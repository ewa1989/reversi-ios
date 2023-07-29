//
//  ReversiGameTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/07/30.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest

final class ReversiGameTest: XCTestCase {
    private var game: ReversiGame!

    override func setUpWithError() throws {
        game = ReversiGame()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_白のディスクをボードの一番先頭に置ける() throws {
        XCTAssertEqual(game.board.countDisks(of: .light), 0)

        game.board.setDisk(.light, atX: 0, y: 0)

        XCTAssertEqual(game.board.countDisks(of: .light), 1)
        XCTAssertEqual(game.board.diskAt(x: 0, y: 0), .light)
    }

    func test_黒のディスクをボードの一番末尾に置ける() throws {
        XCTAssertEqual(game.board.countDisks(of: .light), 0)

        game.board.setDisk(.dark, atX: 7, y: 7)

        XCTAssertEqual(game.board.countDisks(of: .dark), 1)
        XCTAssertEqual(game.board.diskAt(x: 7, y: 7), .dark)
    }
}
