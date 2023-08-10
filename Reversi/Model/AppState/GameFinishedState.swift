//
//  GameFinishedState.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

/// ゲーム終了を表すアプリの状態です。
class GameFinishedState<Repository: ReversiGameRepository, Dispatcher: Dispatchable>: AppState {
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
        precondition(
            game.turn == nil
        )
        self.game = game
        self.repository = repository
        self.dispatcher = dispatcher
        self.output = output
    }

    func start() {
        output.game.accept(game)
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
        try repository.save(game)
        return self
    }

    func reset() throws -> AppState {
        let newGame = ReversiGame.newGame()
        let updates = DiskPlacement.allCellsFrom(game: newGame, animated: false)

        return UpdatingViewState(
            game: newGame,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: updates,
            isReset: true
        )
    }

    func finishUpdatingOneCell(isFinished: Bool) throws -> AppState {
        throw InvalidActionError()
    }
}
