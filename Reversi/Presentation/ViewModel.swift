//
//  ViewModel.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/01.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class ViewModel<Repository: ReversiGameRepository, Dispatcher: Dispatchable> {
    /// リファクタリング最中の暫定措置として参照を持っているだけなので後で消す予定
    private weak var viewController: ViewController!
    private let repository: Repository
    private let dispatcher: Dispatcher

    /// ゲームの状態を管理します
    let game = BehaviorRelay(value: ReversiGame())

    public let diskCounts: Observable<[Int]>
    public let message: Observable<(Disk?, String)>
    public let playerControls: Observable<[Player]>
    public let messageDiskSize: Observable<CGFloat>

    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `initialDiskSize` に保管された値を使います。
    private let initialDiskSize: CGFloat

    private let _computerProcessing = BehaviorRelay(value: [false, false])
    /// コンピューターの思考状態を表します。
    /// `true`: 思考中です。
    /// `false`: 思考中ではりません。
    public var computerProcessings: Observable<[Bool]> {
        _computerProcessing.asObservable()
    }

    private let _passAlert = PublishRelay<Void>()
    /// パスのアラートを表示すべきタイミングを通知します。
    public var passAlert: Observable<Void> {
        _passAlert.asObservable()
    }

    private var viewHasAppeared: Bool = false

    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }

    private var playerCancellers: [Disk: Canceller] = [:]

    init(
        viewController: ViewController!,
        gameRepository: Repository,
        dispatcher: Dispatcher,
        initialDiskSize: CGFloat
    ) {
        self.viewController = viewController
        self.repository = gameRepository
        self.dispatcher = dispatcher
        self.initialDiskSize = initialDiskSize

        messageDiskSize = game.map { $0.state }.map { state in
            state == .draw ? 0 : initialDiskSize
        }
        diskCounts = game.map { $0.board.diskCounts }
        message = game.map { $0.state }.map {
            switch $0 {
            case .move(side: let side):
                return (side, "'s turn")
            case .win(winner: let winner):
                return (winner, " won")
            case .draw:
                return (nil ,"Tied")
            }
        }
        playerControls = game.map { $0.playerControls }
    }
}

// MARK: Event from View

extension ViewModel {
    func viewDidLoad() {
        do {
            try loadGame()
        } catch _ {
            newGame()
        }
    }

    func viewDidAppear() {
        if viewHasAppeared { return }
        viewHasAppeared = true
        waitForPlayer()
    }

    func reset() {
        animationCanceller?.cancel()
        animationCanceller = nil

        for side in Disk.sides {
            playerCancellers[side]?.cancel()
            playerCancellers.removeValue(forKey: side)
        }

        newGame()
        waitForPlayer()
    }

    func changePlayerControl(of side: Disk, to player: Player) {
        var value = game.value
        value.playerControls[side.index] = player
        game.accept(value)

        try? repository.save(game.value)

        if let canceller = playerCancellers[side] {
            canceller.cancel()
        }

        if !isAnimating, side == game.value.turn, case .computer = player {
            playTurnOfComputer()
        }
    }

    func didSelectCellAt(x: Int, y: Int) {
        guard let turn = game.value.turn else { return }
        if isAnimating { return }
        guard case .manual = game.value.playerControls[turn.index] else { return }
        // try? because doing nothing when an error occurs
        try? placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }

    func pass() {
        nextTurn()
    }
}

// MARK: Game Management

extension ViewModel {
    /// ゲームの状態をファイルから読み込み、復元します。
    private func loadGame() throws {
        let value = try repository.load()
        game.accept(value)

        viewController.updateGame()
    }

    /// プレイヤーの行動を待ちます。
    private func waitForPlayer() {
        guard let turn = self.game.value.turn else { return }
        switch game.value.playerControls[turn.index] {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }

    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    private func playTurnOfComputer() {
        guard let turn = self.game.value.turn else { preconditionFailure() }
        let coordinate = game.value.board.validMoves(for: turn).randomElement()!

        _computerProcessing.start(side: turn)

        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self._computerProcessing.finish(side: turn)
            self.playerCancellers[turn] = nil
        }
        let canceller = Canceller(cleanUp)
        dispatcher.asyncAfter(seconds: 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()

            try! self.placeDisk(turn, atX: coordinate.x, y: coordinate.y, animated: true) { [weak self] _ in
                self?.nextTurn()
            }
        }

        playerCancellers[turn] = canceller
    }

    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    private func nextTurn() {
        guard var turn = self.game.value.turn else { return }

        turn.flip()

        if !game.value.board.canPlaceAnyDisks(by: turn) {
            if !game.value.board.canPlaceAnyDisks(by: turn.flipped) {
                var value = game.value
                value.turn = nil
                game.accept(value)
            } else {
                var value = game.value
                value.turn = turn
                game.accept(value)

                _passAlert.accept(())
            }
        } else {
            var value = game.value
            value.turn = turn
            game.accept(value)
            waitForPlayer()
        }
    }

    /// ゲームの状態を初期化し、新しいゲームを開始します。
    private func newGame() {
        let value = ReversiGame.newGame()
        game.accept(value)

        for y in game.value.board.yRange {
            for x in game.value.board.xRange {
                viewController.boardView.setDisk(value.board.diskAt(x: x, y: y), atX: x, y: y, animated: false)
            }
        }

        try? repository.save(game.value)
    }

    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    private func placeDisk(_ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) throws {
        let diskCoordinates = game.value.board.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }

        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.animationCanceller = nil
            }
            animationCanceller = Canceller(cleanUp)
            animateSettingDisks(at: [Coordinate(x: x, y: y)] + diskCoordinates, to: disk) { [weak self] isFinished in
                guard let self = self else { return }
                guard let canceller = self.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(isFinished)
                try? repository.save(game.value)
            }
        } else {
            dispatcher.async { [weak self] in
                guard let self = self else { return }
                var value = self.game.value
                value.board.setDisk(disk, atX: x, y: y)
                game.accept(value)

                self.viewController.boardView.setDisk(disk, atX: x, y: y, animated: false)
                for diskCoordinate in diskCoordinates {
                    value.board.setDisk(disk, atX: diskCoordinate.x, y: diskCoordinate.y)
                    game.accept(value)

                    self.viewController.boardView.setDisk(disk, atX: diskCoordinate.x, y: diskCoordinate.y, animated: false)
                }
                completion?(true)
                try? repository.save(game.value)
            }
        }
    }

    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
    where C.Element == Coordinate
    {
        guard let coordinate = coordinates.first else {
            completion(true)
            return
        }

        let animationCanceller = self.animationCanceller!
        var value = game.value
        value.board.setDisk(disk, atX: coordinate.x, y: coordinate.y)
        game.accept(value)

        viewController.boardView.setDisk(disk, atX: coordinate.x, y: coordinate.y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for coordinate in coordinates {
                    var value = self.game.value
                    value.board.setDisk(disk, atX: coordinate.x, y: coordinate.y)
                    game.accept(value)

                    self.viewController.boardView.setDisk(disk, atX: coordinate.x, y: coordinate.y, animated: false)
                }
                completion(false)
            }
        }
    }
}

private extension BehaviorRelay where Element == [Bool] {
    /// 指定した側のコンピューターの思考状態を思考中に更新します。
    /// - Parameter side: 状態を変更する側です。
    func start(side: Disk) {
        var value = self.value
        value[side.index] = true
        self.accept(value)
    }

    /// 指定した側のコンピューターの思考状態を思考終了に更新します。
    /// - Parameter side: 状態を変更する側です。
    func finish(side: Disk) {
        var value = self.value
        value[side.index] = false
        self.accept(value)
    }
}

// MARK: Additional types

final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?

    init(_ body: (() -> Void)?) {
        self.body = body
    }

    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}
