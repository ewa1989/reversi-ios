//
//  UpdatingViewState.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

/// 画面描画中を表すアプリの状態です。
class UpdatingViewState<Repository: ReversiGameRepository, Dispatcher: Dispatchable>: AppState {
    var game: ReversiGame

    private let repository: Repository
    private let dispatcher: Dispatcher
    private let output: AppStateOutput

    private var updates: [DiskPlacement]

    init(
        game: ReversiGame,
        repository: Repository,
        dispatcher: Dispatcher,
        output: AppStateOutput,
        updates: [DiskPlacement]
    ) {
        // 最後の1セル描画中にモード切り替えが呼ばれた場合にupdatesは空になり得る
        precondition(
            game.turn != nil
        )
        self.game = game
        self.repository = repository
        self.dispatcher = dispatcher
        self.output = output
        self.updates = updates
    }

    func start() {
        dispatcher.async { [weak self] in
            guard let self = self else { return }
            let first = self.updates.removeFirst()
            self.output.diskToPlace.accept(first)
        }
    }

    func inputByUser(coordinate: Coordinate) throws -> AppState {
        throw InvalidActionError()
    }

    func inputByComputer(coordinate: Coordinate) throws -> AppState {
        throw InvalidActionError()
    }

    func acceptPass() throws -> AppState {
        throw InvalidActionError()
    }

    func changePlayerControl(of side: Disk, to player: Player) throws -> AppState {
        game.playerControls[side.index] = player
        return self
    }

    func reset() -> AppState {
        self
    }

    func finishUpdatingOneCell() throws -> AppState {
        self
    }
}
