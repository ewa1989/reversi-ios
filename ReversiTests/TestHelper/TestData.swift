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
    case blankSurroundedByLightSurroundingByDark = "x00\nxxxxx---\nxooox---\nxo-ox---\nxooox---\nxxxxx---\n--------\n--------\n--------\n"

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

    /// プレイヤーモードはどちらもManual、中央に白黒2つずつディスクが置かれ黒から始まる新規ゲームを作成します。
    case newGame = "x00\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"

    /// 黒のコンピューターから始まり、必ず(2, 0)に置かれるゲームを作成します。
    /// ```
    /// xo----xo
    /// --------
    /// --------
    /// --------
    /// --------
    /// --------
    /// --------
    /// --------
    /// ```
    case startFromDarkComputerOnlyPlaceAt2_0 = "x10\nxo----xo\n--------\n--------\n--------\n--------\n--------\n--------\n--------\n"

    /// 黒から始まり次の白のターンで必ずパスが発生するゲームを作成します。
    /// ```
    /// xo------
    /// o-------
    /// --------
    /// --------
    /// --------
    /// --------
    /// --------
    /// --------
    /// ```
    case mustPassOnNextTurn = "x00\nxo------\no-------\n--------\n--------\n--------\n--------\n--------\n--------\n"

    /// 白から始まり1手で必ず引き分けになるゲームを作成します。
    /// ```
    /// xxxxoooo
    /// xxxxoooo
    /// xxxxoooo
    /// xxxxoooo
    /// xxxxoooo
    /// xxxxoooo
    /// xxxxoooo
    /// xxxxoox-
    /// ```
    case willDrawOnNextTurn = "o00\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoox-\n"

    /// 両プレイヤーコンピューター、白から始まるけれどどこにも置けず、すぐパスが必要なゲームを作成します。
    /// ```
    /// xo------
    /// o-------
    /// --------
    /// --------
    /// --------
    /// --------
    /// --------
    /// --------
    /// ```
    case mustPassOnThisTurn = "o11\nxo------\no-------\n--------\n--------\n--------\n--------\n--------\n--------\n"

    /// 黒から始まるけれど、どちらのプレイヤーも置く場所がないゲームを作成します。
    /// ```
    /// xxxxx---
    /// xxxxx---
    /// xxxxx---
    /// xxxxx---
    /// xxxxx---
    /// --------
    /// --------
    /// --------
    /// ```
    case unfinishedButNowhereToPlace = "x00\nxxxxx---\nxxxxx---\nxxxxx---\nxxxxx---\nxxxxx---\n--------\n--------\n--------\n"

    /// プレイヤーモードはどちらもComputer、中央に白黒2つずつディスクが置かれ白から始まる新規ゲームを作成します。
    case newGameStartFromBothComputer = "x11\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"
}
