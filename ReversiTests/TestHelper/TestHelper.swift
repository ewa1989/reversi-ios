//
//  TestHelper.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/07/30.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

// MARK: Helper

func newGameStartFromLight() -> ReversiGame {
    var game = ReversiGame.newGame()
    game.turn?.flip()
    return game
}

func tiedComputerMatchWithLeftSideDarkAndRightSideLightBoard() -> ReversiGame {
    var game = ReversiGame.newGame()
    game.turn = nil
    game.playerControls = [.computer, .computer]
    for y in game.board.yRange {
        for x in 0..<game.board.height / 2 {
            game.board.setDisk(.dark, atX: x, y: y)
        }
        for x in game.board.height / 2..<game.board.height {
            game.board.setDisk(.light, atX: x, y: y)
        }
    }
    return game
}
