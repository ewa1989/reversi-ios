//
//  TestHelper.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/07/30.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

// MARK: Helper

/// プレイヤーモードはどちらもManual、中央に白黒2つずつディスクが置かれ白から始まる新規ゲームを作成します。
func newGameStartFromLight() -> ReversiGame {
    var game = ReversiGame.newGame()
    game.turn?.flip()
    return game
}

/// 左半分が黒、右半分が白でコンピューター同士が引き分けたゲームを作成します。
/// ```
/// xxxxoooo
/// xxxxoooo
/// xxxxoooo
/// xxxxoooo
/// xxxxoooo
/// xxxxoooo
/// xxxxoooo
/// xxxxoooo
/// ```
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

/// 黒が白に囲まれたゲームを作成します。
/// ```
/// --------
/// -ooo----
/// -oxo----
/// -ooo----
/// --------
/// --------
/// --------
/// --------
/// ```
func darkSurroundedByLightGame() -> ReversiGame {
    return try! FileParser.makeGameParsing("x00\n--------\n-ooo----\n-oxo----\n-ooo----\n--------\n--------\n--------\n--------\n")
}

/// 空白の周りを白、その周りを黒が囲んだゲームを作成します。
/// ```
/// xxxxx---
/// xooox---
/// xo-ox---
/// xooox---
/// xxxxx---
/// --------
/// --------
/// --------
/// ```
func blankSurroundedByLightSurroundingByDark() -> ReversiGame {
    return try! FileParser.makeGameParsing("x00\nxxxxx---\nxooox---\nxo#ox---\nxooox---\nxxxxx---\n--------\n--------\n--------\n")
}

/// 全マス黒で埋まったゲームを作成します。
func allDarkBoard() -> ReversiGame {
    return try! FileParser.makeGameParsing("-00\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\n")
}

/// 全マス白で埋まったゲームを作成します。
func allLightBoard() -> ReversiGame {
    return try! FileParser.makeGameParsing("-00\noooooooo\noooooooo\noooooooo\noooooooo\noooooooo\noooooooo\noooooooo\noooooooo\n")
}
