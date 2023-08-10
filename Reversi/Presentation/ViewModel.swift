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

final class ViewModel<Repository: ReversiGameRepository, Dispatcher: Dispatchable> {
    // MARK: publicのストリーム
    public let diskCounts: Observable<[Int]>
    public let message: Observable<Message>
    public let playerControls: Observable<[Player]>
    public let messageDiskSize: Observable<CGFloat>
    /// 直近で一番最初に画面更新する必要があるディスクを流すObservableです。
    public var diskToPlace: Observable<DiskPlacement> {
        output.diskToPlace.asObservable()
    }
    /// コンピューターの思考状態を表します。
    /// `true`: 思考中です。
    /// `false`: 思考中ではりません。
    public var computerProcessings: Observable<[Bool]> {
        output.computerProcessing.distinctUntilChanged().asObservable()
    }
    /// パスのアラートを表示すべきタイミングを通知します。
    public var passAlert: Observable<PassAlert> {
        output.passAlert.asObservable()
    }

    // MARK: DIされたもの
    private let repository: Repository
    private let dispatcher: Dispatcher

    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `initialDiskSize` に保管された値を使います。
    private let initialDiskSize: CGFloat
    private var viewHasAppeared: Bool = false

    private var appState: AppState?
    private let output: AppStateOutput

    init(
        gameRepository: Repository,
        dispatcher: Dispatcher,
        initialDiskSize: CGFloat,
        disposeBag: DisposeBag
    ) {
        self.repository = gameRepository
        self.dispatcher = dispatcher
        self.initialDiskSize = initialDiskSize

        output = AppStateOutput(
            game: PublishRelay(),
            computerProcessing: PublishRelay(),
            passAlert: PublishRelay(),
            diskToPlace: PublishRelay(),
            finishComputerProcessing: PublishRelay()
        )

        messageDiskSize = output.game.map { $0.state }.map { state in
            state == .draw ? 0 : initialDiskSize
        }.distinctUntilChanged()
        diskCounts = output.game.map { $0.board.diskCounts }.distinctUntilChanged()
        message = output.game.map { $0.state }.map {
            switch $0 {
            case .move(side: let side):
                return Message(disk: side, label: "'s turn")
            case .win(winner: let winner):
                return Message(disk: winner, label: " won")
            case .draw:
                return Message(disk: nil, label: "Tied")
            }
        }.distinctUntilChanged()
        playerControls = output.game.map { $0.playerControls }.distinctUntilChanged()
        output.finishComputerProcessing.subscribe(onNext: { [weak self] coordinate in
            guard let self = self else { return }
            self.appState = try! self.appState?.inputByComputer(coordinate: coordinate)
            self.appState?.start(viewHasAppeared: self.viewHasAppeared)
        }).disposed(by: disposeBag)
    }
}

// MARK: Event from View

extension ViewModel {
    func viewDidLoad() {
        let game = loadOrCreateNewGame()
        let updates = DiskPlacement.allCellsFrom(game: game, animated: false)
        appState = UpdatingViewState(game: game, repository: repository, dispatcher: dispatcher, output: output, updates: updates, isReset: true, forLoading: true)
        appState?.start(viewHasAppeared: viewHasAppeared)
    }

    private func loadOrCreateNewGame() -> ReversiGame {
        do {
            let loaded = try repository.load()
            return loaded
        } catch {
            let newGame = ReversiGame.newGame()
            try? repository.save(newGame)
            return newGame
        }
    }

    func viewDidAppear() {
        if viewHasAppeared { return }
        viewHasAppeared = true
        appState?.start(viewHasAppeared: viewHasAppeared)
    }

    func reset() {
        appState = try! appState?.reset()
        appState?.start(viewHasAppeared: viewHasAppeared)
    }

    func changePlayerControl(of side: Disk, to player: Player) {
        appState = try! appState?.changePlayerControl(of: side, to: player)
        appState?.start(viewHasAppeared: viewHasAppeared)
    }

    func didSelectCellAt(x: Int, y: Int) {
        do {
            appState = try appState?.inputByUser(coordinate: Coordinate(x: x, y: y))
            appState?.start(viewHasAppeared: viewHasAppeared)
        } catch {}
    }

    func pass() {
        appState = try! appState?.acceptPass()
        appState?.start(viewHasAppeared: viewHasAppeared)
    }

    func finishToPlace(isFinished: Bool) {
        do {
            appState = try appState?.finishUpdatingOneCell(isFinished: isFinished)
            appState?.start(viewHasAppeared: viewHasAppeared)
        } catch {}
    }
}
