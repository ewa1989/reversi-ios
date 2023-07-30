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

    // MARK: load

    func test_ゲームの初期状態_黒のターン_プレイヤーモードどちらもマニュアル_中央に白黒2つずつのゲームを復元できる() throws {
        fakeStrategy.fakeInput = "x00\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"

        let actual = try repository.load()

        XCTAssertEqual(actual, ReversiGame.newGame())
    }

    func test_白のターンで始まるゲームを復元できる() throws {
        fakeStrategy.fakeInput = "o00\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"

        let expected = newGameStartFromLight()

        let actual = try repository.load()

        XCTAssertEqual(actual, expected)
    }

    func test_引き分け_プレイヤーモードどちらもコンピューター_左半分が黒で右半分が白のゲームを復元できる() throws {
        fakeStrategy.fakeInput = "-11\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\n"

        let expected = tiedComputerMatchWithLeftSideDarkAndRightSideLightBoard()

        let actual = try repository.load()

        XCTAssertEqual(actual, expected)
    }

    // MARK: save

    func test_ゲームの初期状態_黒のターン_プレイヤーモードどちらもマニュアル_中央に白黒2つずつのゲームを保存できる() throws {
        let expected = "x00\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"

        try repository.save(ReversiGame.newGame())
        let actual = fakeStrategy.fakeOutput

        XCTAssertEqual(actual, expected)
    }

    func test_白のターンで始まるゲームを保存できる() throws {
        let expected = "o00\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n"

        try repository.save(newGameStartFromLight())
        let actual = fakeStrategy.fakeOutput

        XCTAssertEqual(actual, expected)
    }

    func test_引き分け_プレイヤーモードどちらもコンピューター_左半分が黒で右半分が白のゲームを保存できる() throws {
        let expected = "-11\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\n"

        try repository.save(tiedComputerMatchWithLeftSideDarkAndRightSideLightBoard())
        let actual = fakeStrategy.fakeOutput

        XCTAssertEqual(actual, expected)
    }
}

private class FakeFileSaveAndLoadStrategy: FileSaveAndLoadStrategy {
    var fakeInput: String = ""
    func load() throws -> String {
        fakeInput
    }

    var fakeOutput: String?
    func save(_ output: String) throws {
        fakeOutput = output
    }
}
