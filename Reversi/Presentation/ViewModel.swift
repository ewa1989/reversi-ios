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
    var game = ReversiGame()

    private var viewHasAppeared: Bool = false

    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `initialDiskSize` に保管された値を使います。
    let initialDiskSize: CGFloat

    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }

    private var playerCancellers: [Disk: Canceller] = [:]

    private let _computerProcessing = BehaviorRelay(value: [false, false])
    /// コンピューターの思考状態を表します。
    /// `true`: 思考中です。
    /// `false`: 思考中ではりません。
    public var computerProcessing: Observable<[Bool]> {
        _computerProcessing.asObservable()
    }

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
    }

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
        game.playerControls[side.index] = player

        try? repository.save(game)

        if let canceller = playerCancellers[side] {
            canceller.cancel()
        }

        if !isAnimating, side == game.turn, case .computer = player {
            playTurnOfComputer()
        }
    }

    func didSelectCellAt(x: Int, y: Int) {
        guard let turn = game.turn else { return }
        if isAnimating { return }
        guard case .manual = game.playerControls[turn.index] else { return }
        // try? because doing nothing when an error occurs
        try? placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }

    /// ゲームの状態をファイルから読み込み、復元します。
    private func loadGame() throws {
        game = try repository.load()

        viewController.updateGame()
        viewController.updateMessageViews()
        viewController.updateCountLabels()
    }

    /// プレイヤーの行動を待ちます。
    private func waitForPlayer() {
        guard let turn = self.game.turn else { return }
        switch game.playerControls[turn.index] {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }

    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    private func playTurnOfComputer() {
        guard let turn = self.game.turn else { preconditionFailure() }
        let coordinate = game.board.validMoves(for: turn).randomElement()!

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
        guard var turn = self.game.turn else { return }

        turn.flip()

        if !game.board.canPlaceAnyDisks(by: turn) {
            if !game.board.canPlaceAnyDisks(by: turn.flipped) {
                game.turn = nil
                viewController.updateMessageViews()
            } else {
                game.turn = turn
                viewController.updateMessageViews()

                viewController.showPassAlert() { [weak self] _ in
                    self?.nextTurn()
                }
            }
        } else {
            game.turn = turn
            viewController.updateMessageViews()
            waitForPlayer()
        }
    }

    /// ゲームの状態を初期化し、新しいゲームを開始します。
    private func newGame() {
        game = ReversiGame.newGame()

        for side in Disk.sides {
            viewController.playerControls[side.index].selectedSegmentIndex = game.playerControls[side.index].rawValue
        }

        for y in game.board.yRange {
            for x in game.board.xRange {
                viewController.boardView.setDisk(game.board.diskAt(x: x, y: y), atX: x, y: y, animated: false)
            }
        }

        viewController.updateMessageViews()
        viewController.updateCountLabels()

        try? repository.save(game)
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
        let diskCoordinates = game.board.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
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
                try? repository.save(game)
                self.viewController.updateCountLabels()
            }
        } else {
            dispatcher.async { [weak self] in
                guard let self = self else { return }
                self.game.board.setDisk(disk, atX: x, y: y)

                self.viewController.boardView.setDisk(disk, atX: x, y: y, animated: false)
                for diskCoordinate in diskCoordinates {
                    self.game.board.setDisk(disk, atX: diskCoordinate.x, y: diskCoordinate.y)

                    self.viewController.boardView.setDisk(disk, atX: diskCoordinate.x, y: diskCoordinate.y, animated: false)
                }
                completion?(true)
                try? repository.save(game)
                self.viewController.updateCountLabels()
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
        game.board.setDisk(disk, atX: coordinate.x, y: coordinate.y)

        viewController.boardView.setDisk(disk, atX: coordinate.x, y: coordinate.y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for coordinate in coordinates {
                    self.game.board.setDisk(disk, atX: coordinate.x, y: coordinate.y)

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
