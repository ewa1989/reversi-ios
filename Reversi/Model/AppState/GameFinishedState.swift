//
//  GameFinishedState.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

/// ゲーム終了を表すアプリの状態です。
class GameFinishedState: AppState {
    var game: ReversiGame

    init(game: ReversiGame) {
        precondition(
            game.turn == nil
        )
        self.game = game
    }

    func inputByUser(coordinate: Coordinate) throws -> AppState {
        throw InvalidActionError()
    }
}
