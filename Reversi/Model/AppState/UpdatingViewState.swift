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

    init(
        game: ReversiGame,
        repository: Repository,
        dispatcher: Dispatcher,
        output: AppStateOutput
    ) {
        self.game = game
        self.repository = repository
        self.dispatcher = dispatcher
        self.output = output
    }

    func start() {

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

    func changePlayerMode(of side: Disk, to player: Player) -> AppState {
        self
    }

    func reset() -> AppState {
        self
    }

    func finishUpdatingOneCell() throws -> AppState {
        self
    }
}
