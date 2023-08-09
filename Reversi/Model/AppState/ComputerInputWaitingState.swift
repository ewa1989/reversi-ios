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
    var game: ReversiGame

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

    func start() {
        output.game.accept(game)
        guard let turn = game.turn else { preconditionFailure() }
        let selected = game.board.validMoves(for: turn).randomElement()!

        output.computerProcessing.start(side: turn)
        dispatcher.asyncAfter(seconds: 2.0) { [weak self] in
            guard let self = self else { return }
            if (self.cancelled) { return }
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
            updates: updates
        )
    }

    func acceptPass() throws -> AppState {
        throw InvalidActionError()
    }

    func changePlayerMode(of side: Disk, to player: Player) -> AppState {
        self
    }

    func reset() -> AppState {
        cancelled = true
        return self
    }

    func finishUpdatingOneCell() throws -> AppState {
        throw InvalidActionError()
    }
}

private extension PublishRelay where Element == [Bool] {
    /// 指定した側のコンピューターの思考状態を思考中に更新します。
    /// - Parameter side: 状態を変更する側です。
    func start(side: Disk) {
        var value = [false, false]
        value[side.index] = true
        self.accept(value)
    }

    /// コンピューターの思考状態を思考終了に更新します。
    func finish() {
        self.accept([false, false])
    }
}
