//
//  ReversiGameRepositoryTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/07/30.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest

final class ReversiGameRepositoryTest: XCTestCase {
    private var repository: ReversiGameRepository!
    private var fakeStrategy: FakeFileSaveAndLoadStrategy!

    override func setUpWithError() throws {
        fakeStrategy = FakeFileSaveAndLoadStrategy()
        repository = ReversiGameRepositoryImpl(strategy: fakeStrategy)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_ゲームの初期状態_黒のターン_プレイヤーモードどちらもマニュアル_中央に白黒2つずつのゲームを復元できる() throws {
        fakeStrategy.fakeResult = "x00\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"

        let game = try repository.loadGameFromFile()

        XCTAssertEqual(game.turn, .dark)
        XCTAssertEqual(game.playerControls, [.manual, .manual])
        XCTAssertEqual(game.board.countDisks(of: .dark), 2)
        XCTAssertEqual(game.board.countDisks(of: .light), 2)
        XCTAssertEqual(game.board.diskAt(x: 3, y: 3), .light)
        XCTAssertEqual(game.board.diskAt(x: 4, y: 3), .dark)
        XCTAssertEqual(game.board.diskAt(x: 3, y: 4), .dark)
        XCTAssertEqual(game.board.diskAt(x: 4, y: 4), .light)
    }

    func test_白のターンで始まるゲームを復元できる() throws {
        fakeStrategy.fakeResult = "o00\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"

        let game = try repository.loadGameFromFile()

        XCTAssertEqual(game.turn, .light)
    }

    func test_引き分け_プレイヤーモードどちらもコンピューター_左半分が黒で右半分が白のゲームを復元できる() throws {
        fakeStrategy.fakeResult = "-11\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\n"

        let game = try repository.loadGameFromFile()

        XCTAssertEqual(game.turn, nil)
        XCTAssertEqual(game.playerControls, [.computer, .computer])
        XCTAssertEqual(game.board.countDisks(of: .dark), 32)
        XCTAssertEqual(game.board.countDisks(of: .light), 32)

        for y in game.board.yRange {
            for x in 0..<game.board.height / 2 {
                XCTAssertEqual(game.board.diskAt(x: x, y: y), .dark)
            }
            for x in game.board.height / 2..<game.board.height {
                XCTAssertEqual(game.board.diskAt(x: x, y: y), .light)
            }
        }
    }
}

private class FakeFileSaveAndLoadStrategy: FileSaveAndLoadStrategy {
    var fakeResult: String = ""
    func loadFile() throws -> String {
        fakeResult
    }
}
