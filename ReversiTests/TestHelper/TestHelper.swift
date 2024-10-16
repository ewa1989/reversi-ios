//
//  TestData.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/07/30.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

enum TestData: String {
    var game: ReversiGame {
        try! FileParser.makeGameParsing(self.rawValue)
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
    case darkSurroundedByLightGame = "x00\n--------\n-ooo----\n-oxo----\n-ooo----\n--------\n--------\n--------\n--------\n"

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
    case blankSurroundedByLightSurroundingByDark = "x00\nxxxxx---\nxooox---\nxo#ox---\nxooox---\nxxxxx---\n--------\n--------\n--------\n"

    /// 全マス黒で埋まったゲームを作成します。
    case allDarkBoard = "-00\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\nxxxxxxxx\n"

    /// 全マス白で埋まったゲームを作成します。
    case allLightBoard = "-00\noooooooo\noooooooo\noooooooo\noooooooo\noooooooo\noooooooo\noooooooo\noooooooo\n"

    /// プレイヤーモードはどちらもManual、中央に白黒2つずつディスクが置かれ白から始まる新規ゲームを作成します。
    case newGameStartFromLight = "o00\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"

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
    case tiedComputerMatchWithLeftSideDarkAndRightSideLightBoard = "-11\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\n"

    // プレイヤーモードはどちらもManual、中央に白黒2つずつディスクが置かれ黒から始まる新規ゲームを作成します。
    case newGame = "x00\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"
}
