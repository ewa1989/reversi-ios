//
//  ComputerInputWaitingState.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

/// コンピューター入力待ちを表すアプリの状態です。
class ComputerInputWaitingState: AppState {
    var game: ReversiGame

    init(game: ReversiGame) {
        precondition(
            game.turn != nil &&
            game.playerControls[game.turn!.index] == .computer &&
            !game.needsPass()
        )
        self.game = game
    }

    func inputByUser(coordinate: Coordinate) throws -> AppState {
        throw InvalidActionError()
    }
}
