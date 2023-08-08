//
//  PassAcceptWaitingState.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

/// パス了承待ちを表すアプリの状態です。
class PassAcceptWaitingState: AppState {
    var game: ReversiGame

    init(game: ReversiGame) {
        precondition(
            game.turn != nil &&
            game.needsPass()
        )
        self.game = game
    }

    func inputByUser(coordinate: Coordinate) throws -> AppState {
        throw InvalidActionError()
    }

    func inputByComputer(coordinate: Coordinate) throws -> AppState {
        throw InvalidActionError()
    }

    func acceptPass() throws -> AppState {
        self
    }

    func changePlayerMode(of side: Disk, to player: Player) -> AppState {
        self
    }

    func reset() -> AppState {
        self
    }
}
