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
    private let isReset: Bool
    private var cancelled = false

    init(
        game: ReversiGame,
        repository: Repository,
        dispatcher: Dispatcher,
        output: AppStateOutput,
        updates: [DiskPlacement],
        isReset: Bool
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
        self.isReset = isReset
    }

    func start() {
        dispatcher.async { [weak self] in
            guard let self = self else { return }
            if self.cancelled { return }
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
        cancelled = true
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
        if updates.isEmpty {
            if !isReset {
                updateGame()
            }
            try repository.save(game)
            let factory = AppStateFactory(
                repository: repository,
                dispatcher: dispatcher,
                output: output
            )
            return factory.make(from: game)
        }
        if !isFinished {
            updates = updates.map {
                DiskPlacement(
                    disk: $0.disk,
                    coordinate: $0.coordinate,
                    animated: false
                )
            }
        }
        return self
    }

    private func updateGame() {
        guard var turn = game.turn else {
            return
        }

        turn.flip()

        if !game.board.canPlaceAnyDisks(by: turn) {
            if !game.board.canPlaceAnyDisks(by: turn.flipped) {
                game.turn = nil
                return
            }
        }

        game.turn = turn
    }
}
