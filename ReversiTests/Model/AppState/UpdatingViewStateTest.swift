//
//  UpdatingViewStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest

final class UpdatingViewStateTest: XCTestCase {
    private var state: UpdatingViewState!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_画面描画中の時_ユーザー入力不可能() throws {
        state = UpdatingViewState(game: TestData.willDrawOnNextTurn.game)
        XCTAssertThrowsError(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_画面描画中の時_コンピューター入力不可能() throws {
        state = UpdatingViewState(game: TestData.willDrawOnNextTurn.game)
        XCTAssertThrowsError(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_画面描画中の時_パス了承不可能() throws {
        state = UpdatingViewState(game: TestData.willDrawOnNextTurn.game)
        XCTAssertThrowsError(try state.acceptPass())
    }
}
