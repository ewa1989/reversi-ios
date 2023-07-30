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

    /// プレイヤーモードはどちらもManual、中央に白黒2つずつディスクが置かれ黒から始まる新規ゲームを作成します。
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

    /// 盤上に置かれたディスクの枚数が多い方の色を返します。
    /// 引き分けの場合は `nil` が返されます。
    /// - Returns: 盤上に置かれたディスクの枚数が多い方の色です。引き分けの場合は `nil` を返します。
    public func sideWithMoreDisks() -> Disk? {
        let darkCount = countDisks(of: .dark)
        let lightCount = countDisks(of: .light)
        if darkCount == lightCount {
            return nil
        } else {
            return darkCount > lightCount ? .dark : .light
        }
    }

    /// 指定された位置にディスクを置いた時に、裏返るディスクの位置のコレクションを返します。
    /// コレクションの順番はディスクを裏返す処理を行う順番
    /// 「左上、上、右上、右、右下、下、左下、左」
    /// と一致しています。
    /// - Parameters:
    ///   - disk: 置くディスクの色です。
    ///   - x: 置くセルの列です。
    ///   - y: 置くセルの行です。
    /// - Returns: 裏返るディスクの位置のコレクションです。置くディスクの位置は含みません。裏返るディスクがない場合は空のコレクションを返します。すでにディスクが存在するセルを指定した場合は空のコレクションを返します。
    public func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) -> [Coordinate] {
        let directions = [
            (x: -1, y: -1),
            (x:  0, y: -1),
            (x:  1, y: -1),
            (x:  1, y:  0),
            (x:  1, y:  1),
            (x:  0, y:  1),
            (x: -1, y:  1),
            (x: -1, y:  0),
        ]

        guard diskAt(x: x, y: y) == nil else {
            return []
        }

        var diskCoordinates: [(Int, Int)] = []

        for direction in directions {
            var x = x
            var y = y

            var diskCoordinatesInLine: [(Int, Int)] = []
        flipping: while true {
            x += direction.x
            y += direction.y

            switch (disk, diskAt(x: x, y: y)) { // Uses tuples to make patterns exhaustive
            case (.dark, .some(.dark)), (.light, .some(.light)):
                diskCoordinates.append(contentsOf: diskCoordinatesInLine)
                break flipping
            case (.dark, .some(.light)), (.light, .some(.dark)):
                diskCoordinatesInLine.append((x, y))
            case (_, .none):
                break flipping
            }
        }
        }

        return diskCoordinates.toCoordinates()
    }

    /// `x`, `y` で指定されたセルに、 `disk` が置けるかを調べます。
    /// ディスクを置くためには、少なくとも 1 枚のディスクをひっくり返せる必要があります。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: 指定されたセルに `disk` を置ける場合は `true` を、置けない場合は `false` を返します。
    func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int) -> Bool {
        !flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y).toTuples().isEmpty
    }
}

struct Cell: Hashable {
    var disk: Disk?
}

enum Player: Int, CaseIterable {
    case manual = 0
    case computer = 1
}

struct Coordinate: Hashable {
    let (x, y): (Int, Int)
}

extension Collection where Element == Coordinate {
    func toTuples() -> [(Int, Int)] {
        self.map { ($0.x, $0.y) }
    }
}

extension Collection where Element == (Int, Int) {
    func toCoordinates() -> [Coordinate] {
        map { Coordinate(x: $0.0, y: $0.1) }
    }
}
