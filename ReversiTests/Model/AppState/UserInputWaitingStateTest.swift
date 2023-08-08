//
//  UserInputWaitingStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest

final class UserInputWaitingStateTest: XCTestCase {
    private var state: UserInputWaitingState!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_ユーザー入力待ちの時_ユーザー入力可能() throws {
        state = UserInputWaitingState(game: TestData.newGame.game)
        XCTAssertNoThrow(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_ユーザー入力待ちの時_コンピューター入力不可能() throws {
        state = UserInputWaitingState(game: TestData.newGame.game)
        XCTAssertThrowsError(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_ユーザー入力待ちの時_パス了承不可能() throws {
        state = UserInputWaitingState(game: TestData.newGame.game)
        XCTAssertThrowsError(try state.acceptPass())
    }

    func test_ユーザー入力待ちの時_モード切り替え可能() throws {
        state = UserInputWaitingState(game: TestData.newGame.game)
        XCTAssertNoThrow(state.changePlayerMode(of: .dark, to: .manual))
    }
}
