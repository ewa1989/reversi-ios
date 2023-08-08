//
//  PassAcceptWaitingStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest

final class PassAcceptWaitingStateTest: XCTestCase {
    private var state: PassAcceptWaitingState!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_パス了承待ちの時_ユーザー入力不可能() throws {
        state = PassAcceptWaitingState(game: TestData.mustPassOnThisTurn.game)
        XCTAssertThrowsError(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_パス了承待ちの時_コンピューター入力不可能() throws {
        state = PassAcceptWaitingState(game: TestData.mustPassOnThisTurn.game)
        XCTAssertThrowsError(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_パス了承待ちの時_パス了承可能() throws {
        state = PassAcceptWaitingState(game: TestData.mustPassOnThisTurn.game)
        XCTAssertNoThrow(try state.acceptPass())
    }

    func test_パス了承待ちの時_モード切り替え可能() throws {
        state = PassAcceptWaitingState(game: TestData.mustPassOnThisTurn.game)
        XCTAssertNoThrow(state.changePlayerMode(of: .dark, to: .manual))
    }
}
