//
//  ComputerInputWaitingStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxRelay

final class ComputerInputWaitingStateTest: XCTestCase {
    private var state: ComputerInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
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

    func test_コンピューター入力待ちの時_ユーザー入力不可能() throws {
        state = ComputerInputWaitingState(
            game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_コンピューター入力待ちの時_コンピューター入力可能() throws {
        state = ComputerInputWaitingState(
            game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertNoThrow(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_コンピューター入力待ちの時_パス了承不可能() throws {
        state = ComputerInputWaitingState(
            game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.acceptPass())
    }

    func test_コンピューター入力待ちの時_モード切り替え可能() throws {
        state = ComputerInputWaitingState(
            game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertNoThrow(state.changePlayerMode(of: .dark, to: .manual))
    }

    func test_コンピューター入力待ちの時_リセット可能() throws {
        state = ComputerInputWaitingState(
            game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertNoThrow(state.reset())
    }

    func test_コンピューター入力待ちの時_セル描画完了不可能() throws {
        state = ComputerInputWaitingState(
            game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.finishUpdatingOneCell())
    }
}
