//
//  PassAcceptWaitingState.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

/// パス了承待ちを表すアプリの状態です。
class PassAcceptWaitingState<Repository: ReversiGameRepository, Dispatcher: Dispatchable>: AppState {
    private var game: ReversiGame

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
            game.turn != nil &&
            game.needsPass()
        )
        self.game = game
        self.repository = repository
        self.dispatcher = dispatcher
        self.output = output
    }

    func start(viewHasAppeared: Bool) {
        output.game.accept(game)
        if !viewHasAppeared { return }
        output.passAlert.accept(PassAlert())
    }

    func inputByUser(coordinate: Coordinate) throws -> AppState {
        throw InvalidActionError()
    }

    func inputByComputer(coordinate: Coordinate) throws -> AppState {
        throw InvalidActionError()
    }

    func acceptPass() throws -> AppState {
        game.updateTurn()
        let factory = AppStateFactory(
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        return factory.make(from: game)
    }

    func changePlayerControl(of side: Disk, to player: Player) throws -> AppState {
        throw InvalidActionError()
    }

    func reset() throws -> AppState {
        throw InvalidActionError()
    }

    func finishUpdatingOneCell(isFinished: Bool) throws -> AppState {
        throw InvalidActionError()
    }
}
