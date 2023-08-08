//
//  GameFinishedStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest

final class GameFinishedStateTest: XCTestCase {
    private var state: GameFinishedState!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_ゲーム終了の時_ユーザー入力不可能() throws {
        state = GameFinishedState(game: TestData.allLightBoard.game)
        XCTAssertThrowsError(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_ゲーム終了の時_コンピューター入力不可能() throws {
        state = GameFinishedState(game: TestData.allLightBoard.game)
        XCTAssertThrowsError(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_ゲーム終了の時_パス了承不可能() throws {
        state = GameFinishedState(game: TestData.allLightBoard.game)
        XCTAssertThrowsError(try state.acceptPass())
    }

    func test_ゲーム終了の時_モード切り替え可能() throws {
        state = GameFinishedState(game: TestData.allLightBoard.game)
        XCTAssertNoThrow(state.changePlayerMode(of: .dark, to: .manual))
    }

    func test_ゲーム終了の時_リセット可能() throws {
        state = GameFinishedState(game: TestData.allLightBoard.game)
        XCTAssertNoThrow(state.reset())
    }

    func test_ゲーム終了の時_セル描画完了不可能() throws {
        state = GameFinishedState(game: TestData.allLightBoard.game)
        XCTAssertThrowsError(try state.finishUpdatingOneCell())
    }
}
