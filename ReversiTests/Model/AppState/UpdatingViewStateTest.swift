//
//  UpdatingViewStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxRelay

final class UpdatingViewStateTest: XCTestCase {
    private var state: UpdatingViewState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
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

    func test_画面描画中の時_ユーザー入力不可能() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)]
        )
        XCTAssertThrowsError(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_画面描画中の時_コンピューター入力不可能() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)]
        )
        XCTAssertThrowsError(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_画面描画中の時_パス了承不可能() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)]
        )
        XCTAssertThrowsError(try state.acceptPass())
    }

    func test_画面描画中の時_モード切り替え可能() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)]
        )
        XCTAssertNoThrow(try state.changePlayerControl(of: .dark, to: .manual))
    }

    func test_画面描画中の時_リセット可能() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)]
        )
        XCTAssertNoThrow(state.reset())
    }

    func test_画面描画中の時_セル描画完了可能() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)]
        )
        XCTAssertNoThrow(try state.finishUpdatingOneCell())
    }
}
