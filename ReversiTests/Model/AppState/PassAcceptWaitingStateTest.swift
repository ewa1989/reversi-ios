//
//  PassAcceptWaitingStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxRelay

final class PassAcceptWaitingStateTest: XCTestCase {
    private var state: PassAcceptWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
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

    func test_パス了承待ちの時_ユーザー入力不可能() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassOnThisTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_パス了承待ちの時_コンピューター入力不可能() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassOnThisTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_パス了承待ちの時_パス了承可能() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassOnThisTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertNoThrow(try state.acceptPass())
    }

    func test_パス了承待ちの時_モード切り替え不可能() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassOnThisTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.changePlayerControl(of: .dark, to: .manual))
    }

    func test_パス了承待ちの時_リセット不可能() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassOnThisTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.reset())
    }

    func test_パス了承待ちの時_セル描画完了不可能() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassOnThisTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.finishUpdatingOneCell(isFinished: true))
    }
}
