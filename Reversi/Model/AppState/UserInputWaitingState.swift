//
//  UserInputWaitingState.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

/// ユーザー入力待ちを表すアプリの状態です。
class UserInputWaitingState<Repository: ReversiGameRepository, Dispatcher: Dispatchable>: AppState {
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
            game.playerControls[game.turn!.index] == .manual &&
            !game.needsPass()
        )
        self.game = game
        self.repository = repository
        self.dispatcher = dispatcher
        self.output = output
    }

    func start(viewHasAppeared: Bool) {
        output.game.accept(game)
        output.computerProcessing.finish()
    }

    func inputByUser(coordinate: Coordinate) throws -> AppState {
        guard let turn = game.turn else { preconditionFailure() }
        let flippedCoordinates = game.board.flippedDiskCoordinatesByPlacingDisk(turn, atX: coordinate.x, y: coordinate.y)
        if flippedCoordinates.isEmpty { throw DiskPlacementError(disk: turn, x: coordinate.x, y: coordinate.y) }
        let updateCoordinates = [coordinate] + flippedCoordinates
        let updates = updateCoordinates.map {
            DiskPlacement(disk: turn, coordinate: $0, animated: true)
        }

        return UpdatingViewState(
            game: game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: updates,
            isReset: false,
            forLoading: false
        )
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
        let factory = AppStateFactory(
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        return factory.make(from: game)
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
            isReset: true,
            forLoading: false
        )
    }

    func finishUpdatingOneCell(isFinished: Bool) throws -> AppState {
        throw InvalidActionError()
    }
}

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}
