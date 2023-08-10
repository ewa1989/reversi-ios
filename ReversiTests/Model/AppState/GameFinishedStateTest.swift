//
//  GameFinishedStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxRelay

final class GameFinishedStateTest: XCTestCase {
    private var state: GameFinishedState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
    private var strategy: FakeFileSaveAndLoadStrategy!
    private var repository: ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>!
    private var dispatcher: SynchronousDispatcher!
    private var output: AppStateOutput!

    override func setUpWithError() throws {
        strategy = FakeFileSaveAndLoadStrategy()
        repository = ReversiGameRepositoryImpl(strategy: strategy)
        dispatcher = SynchronousDispatcher()
        output = AppStateOutput(
            game: PublishRelay<ReversiGame>(),
            computerProcessing: PublishRelay<[Bool]>(),
            passAlert: PublishRelay<PassAlert>(),
            diskToPlace: PublishRelay<DiskPlacement>(),
            finishComputerProcessing: PublishRelay<Coordinate>()
        )
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_ゲーム終了の時_ユーザー入力不可能() throws {
        state = GameFinishedState(
            game: TestData.allLightBoard.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_ゲーム終了の時_コンピューター入力不可能() throws {
        state = GameFinishedState(
            game: TestData.allLightBoard.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_ゲーム終了の時_パス了承不可能() throws {
        state = GameFinishedState(
            game: TestData.allLightBoard.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.acceptPass())
    }

    func test_ゲーム終了の時_モード切り替え可能() throws {
        state = GameFinishedState(
            game: TestData.allLightBoard.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertNoThrow(try state.changePlayerControl(of: .dark, to: .manual))
    }

    func test_ゲーム終了の時_リセット可能() throws {
        state = GameFinishedState(
            game: TestData.allLightBoard.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertNoThrow(state.reset())
    }

    func test_ゲーム終了の時_セル描画完了不可能() throws {
        state = GameFinishedState(
            game: TestData.allLightBoard.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.finishUpdatingOneCell(isFinished: true))
    }
}
