//
//  AppStateFactory.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

struct AppStateFactory {
    /// ReversiGameから、アプリの静的な状態を作成します。
    /// - Parameter game: 状態を作成する基となるReversiGameです。
    /// - Returns: アプリの静的な状態です。
    func make(from game: ReversiGame) -> AppState {
        switch game.state {
        case .move(side: let side):
            if (game.needsPass()) {
                return PassAcceptWaitingState(game: game)
            }
            switch game.playerControls[side.index] {
            case .manual:
                return UserInputWaitingState(game: game)
            case .computer:
                return ComputerInputWaitingState(game: game)
            }
        case .win(winner: _):
            fallthrough
        case .draw:
            return GameFinishedState(game: game)
        }
    }
}
