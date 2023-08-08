//
//  UpdatingViewState.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

/// 画面描画中を表すアプリの状態です。
class UpdatingViewState: AppState {
    var game: ReversiGame

    init(game: ReversiGame) {
        self.game = game
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

    func changePlayerMode(of side: Disk, to player: Player) -> AppState {
        self
    }
}
