//
//  AppStateFactoryTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxRelay

final class AppStateFactoryTest: XCTestCase {
    private var factory: AppStateFactory<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!

    override func setUpWithError() throws {
        let repository = ReversiGameRepositoryImpl(strategy: FakeFileSaveAndLoadStrategy())
        let dispatcher = SynchronousDispatcher()
        let output = AppStateOutput(
            game: PublishRelay<ReversiGame>(),
            computerProcessing: PublishRelay<[Bool]>(),
            passAlert: PublishRelay<PassAlert>(),
            diskToPlace: PublishRelay<DiskPlacement>(),
            finishComputerProcessing: PublishRelay<Coordinate>()
        )
        factory = AppStateFactory(
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_新規ゲームはユーザー入力待ち() throws {
        let appState = factory.make(from: TestData.newGame.game)
        XCTAssertTrue(appState is UserInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
    }

    func test_コンピューターから始まるゲームはコンピューター入力待ち() throws {
        let appState = factory.make(from: TestData.startFromDarkComputerOnlyPlaceAt2_0.game)
        XCTAssertTrue(appState is ComputerInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
    }

    func test_パスするしかない状態で始まるゲームはパス了承待ち() throws {
        let appState = factory.make(from: TestData.mustPassComputerTurnThenComputerTurn.game)
        XCTAssertTrue(appState is PassAcceptWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
    }

    func test_引き分けゲームはゲーム終了() throws {
        let appState = factory.make(from: TestData.tiedComputerMatchWithLeftSideDarkAndRightSideLightBoard.game)
        XCTAssertTrue(appState is GameFinishedState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
    }

    func test_どちらかが勝っているゲームはゲーム終了() throws {
        let appState = factory.make(from: TestData.allLightBoard.game)
        XCTAssertTrue(appState is GameFinishedState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
    }
}
