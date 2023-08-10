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
            game.turn != nil &&
            game.playerControls[game.turn!.index] == .manual &&
            !game.needsPass()
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
        guard let turn = game.turn else { preconditionFailure() }
        let flippedCoordinates = game.board.flippedDiskCoordinatesByPlacingDisk(turn, atX: coordinate.x, y: coordinate.y)
        if (flippedCoordinates.isEmpty) { throw DiskPlacementError(disk: turn, x: coordinate.x, y: coordinate.y) }
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
            isReset: false
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
        if (side == game.turn && player == .computer) {
            return ComputerInputWaitingState(
                game: game,
                repository: repository,
                dispatcher: dispatcher,
                output: output
            )
        }
        return self
    }

    func reset() -> AppState {
        self
    }

    func finishUpdatingOneCell(isFinished: Bool) throws -> AppState {
        throw InvalidActionError()
    }
}
