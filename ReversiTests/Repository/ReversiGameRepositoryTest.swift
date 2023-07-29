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

        let actual = try repository.load()

        XCTAssertEqual(actual, ReversiGame.newGame())
    }

    func test_白のターンで始まるゲームを復元できる() throws {
        fakeStrategy.fakeResult = "o00\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"

        var expected = ReversiGame.newGame()
        expected.turn?.flip()

        let actual = try repository.load()

        XCTAssertEqual(actual, expected)
    }

    func test_引き分け_プレイヤーモードどちらもコンピューター_左半分が黒で右半分が白のゲームを復元できる() throws {
        fakeStrategy.fakeResult = "-11\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\n"

        var expected = ReversiGame.newGame()
        expected.turn = nil
        expected.playerControls = [.computer, .computer]
        for y in expected.board.yRange {
            for x in 0..<expected.board.height / 2 {
                expected.board.setDisk(.dark, atX: x, y: y)
            }
            for x in expected.board.height / 2..<expected.board.height {
                expected.board.setDisk(.light, atX: x, y: y)
            }
        }

        let actual = try repository.load()

        XCTAssertEqual(actual, expected)
    }
}

private class FakeFileSaveAndLoadStrategy: FileSaveAndLoadStrategy {
    var fakeResult: String = ""
    func load() throws -> String {
        fakeResult
    }
}
