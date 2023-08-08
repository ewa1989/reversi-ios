//
//  ComputerInputWaitingStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest

final class ComputerInputWaitingStateTest: XCTestCase {
    private var state: ComputerInputWaitingState!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_コンピューター入力待ちの時_ユーザー入力不可能() throws {
        state = ComputerInputWaitingState(game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game)
        XCTAssertThrowsError(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_コンピューター入力待ちの時_コンピューター入力可能() throws {
        state = ComputerInputWaitingState(game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game)
        XCTAssertNoThrow(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }
}
