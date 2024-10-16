//
//  ComputerInputWaitingState.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation
import RxRelay

/// コンピューター入力待ちを表すアプリの状態です。
class ComputerInputWaitingState<Repository: ReversiGameRepository, Dispatcher: Dispatchable>: AppState {
    private var game: ReversiGame

    private let repository: Repository
    private let dispatcher: Dispatcher
    private let output: AppStateOutput

    private var cancelled = false

    init(
        game: ReversiGame,
        repository: Repository,
        dispatcher: Dispatcher,
        output: AppStateOutput
    ) {
        precondition(
            game.turn != nil &&
            game.playerControls[game.turn!.index] == .computer &&
            !game.needsPass()
        )
        self.game = game
        self.repository = repository
        self.dispatcher = dispatcher
        self.output = output
    }

    func start(viewHasAppeared: Bool) {
        output.game.accept(game)

        if !viewHasAppeared { return }

        guard let turn = game.turn else { preconditionFailure() }
        let selected = game.board.validMoves(for: turn).randomElement()!

        output.computerProcessing.start(side: turn)
        dispatcher.asyncAfter(seconds: 2.0) { [weak self] in
            guard let self = self else { return }
            if self.cancelled { return }
            output.computerProcessing.finish()
            self.output.finishComputerProcessing.accept(selected)
        }
    }

    func inputByUser(coordinate: Coordinate) throws -> AppState {
        throw InvalidActionError()
    }

    func inputByComputer(coordinate: Coordinate) throws -> AppState {
        guard let turn = game.turn else { preconditionFailure() }
        let flippedCoordinates = game.board.flippedDiskCoordinatesByPlacingDisk(turn, atX: coordinate.x, y: coordinate.y)
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
        let newState = factory.make(from: game)
        if newState is Self { return self }
        return newState
    }

    func reset() throws -> AppState {
        cancelled = true
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
