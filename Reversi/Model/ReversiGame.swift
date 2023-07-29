//
//  ReversiGame.swift
//  Reversi
//
//  Created by y-uchida on 2023/07/30.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

struct ReversiGame: Hashable {
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    var turn: Disk?

    /// 各プレイヤーのモードを表します。
    var playerControls: [Player]
    var board: Board

    init() {
        playerControls = Player.allCases.map { _ in .manual }
        board = Board()
    }

    /// プレイヤーモードはどちらもManual、中央に白黒2つずつディスクが置かれ黒のから始まる新規ゲームを作成します。
    static func newGame() -> ReversiGame {
        var game = ReversiGame()
        game.turn = .dark
        game.board.setDisk(.light, atX: game.board.width / 2 - 1, y: game.board.height / 2 - 1)
        game.board.setDisk(.dark, atX: game.board.width / 2, y: game.board.height / 2 - 1)
        game.board.setDisk(.dark, atX: game.board.width / 2 - 1, y: game.board.height / 2)
        game.board.setDisk(.light, atX: game.board.width / 2, y: game.board.height / 2)
        return game
    }
}

struct Board: Hashable {
    /// 盤の幅（ `8` ）を表します。
    public let width: Int = 8

    /// 盤の高さ（ `8` ）を返します。
    public let height: Int = 8

    /// 盤のセルの `x` の範囲（ `0 ..< 8` ）を返します。
    public let xRange: Range<Int>

    /// 盤のセルの `y` の範囲（ `0 ..< 8` ）を返します。
    public let yRange: Range<Int>

    private var cells: [Cell]

    init() {
        xRange = 0 ..< width
        yRange = 0 ..< height
        cells = (0 ..< (width * height)).map { _ in Cell() }
    }

    /// `x`, `y` で指定されたセルの状態を、与えられた `disk` に変更します。
    /// - Parameter disk: セルに設定される新しい状態です。 `nil` はディスクが置かれていない状態を表します。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    public mutating func setDisk(_ disk: Disk?, atX x: Int, y: Int) {
        guard cellAt(x: x, y: y) != nil else {
            preconditionFailure("(\(x), \(y))はボードの範囲外。ボード範囲は x: \(xRange), y: \(yRange)")
        }
        cells[y * width + x] = Cell(disk: disk)
    }

    /// `x`, `y` で指定されたセルの状態を返します。
    /// セルにディスクが置かれていない場合、 `nil` が返されます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: セルにディスクが置かれている場合はそのディスクの値を、置かれていない場合は `nil` を返します。
    public func diskAt(x: Int, y: Int) -> Disk? {
        cellAt(x: x, y: y)?.disk
    }

    private func cellAt(x: Int, y: Int) -> Cell? {
        guard xRange.contains(x) && yRange.contains(y) else { return nil }
        return cells[y * width + x]
    }

    /// `side` で指定された色のディスクが盤上に置かれている枚数を返します。
    /// - Parameter side: 数えるディスクの色です。
    /// - Returns: `side` で指定された色のディスクの、盤上の枚数です。
    public func countDisks(of side: Disk) -> Int {
        cells.filter { $0.disk == side }.count
    }
}

struct Cell: Hashable {
    var disk: Disk?
}

enum Player: Int, CaseIterable {
    case manual = 0
    case computer = 1
}
