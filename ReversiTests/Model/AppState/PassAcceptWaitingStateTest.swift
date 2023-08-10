//
//  PassAcceptWaitingStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxRelay
import RxTest
import RxSwift

final class PassAcceptWaitingStateTest: XCTestCase {
    private var state: PassAcceptWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
    private var strategy: FakeFileSaveAndLoadStrategy!
    private var repository: ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>!
    private var dispatcher: SynchronousDispatcher!
    private var output: AppStateOutput!

    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    private var game: TestableObserver<ReversiGame>!
    private var computerProcessing: TestableObserver<[Bool]>!
    private var passAlert: TestableObserver<PassAlert>!
    private var diskToPlace: TestableObserver<DiskPlacement>!
    private var finishComputerProcessing: TestableObserver<Coordinate>!

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

        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        game = output.game.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        computerProcessing = output.computerProcessing.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        passAlert = output.passAlert.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        diskToPlace = output.diskToPlace.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        finishComputerProcessing = output.finishComputerProcessing.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_パス了承待ちの処理を実行すると_パスするアラートの表示が通知される() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassComputerTurnThenComputerTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )

        scheduler.createColdObservable([
            .next(1, (1)),
        ]).subscribe { [weak self] _ in
            self?.state.start()
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(game.events, [.next(1, TestData.mustPassComputerTurnThenComputerTurn.game)])
        XCTAssertEqual(passAlert.events, [.next(1, PassAlert())])
    }

    func test_パス了承待ちの時_コンピューター入力不可能() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassComputerTurnThenComputerTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_パス了承待ちの時_次がユーザーだと_パス了承するとユーザー入力待ちになる() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassComputerTurnThenUserTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        let newState = try state.acceptPass()
        XCTAssertTrue(newState is UserInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
    }

    func test_パス了承待ちの時_次がコンピューターだと_パス了承するとコンピューター入力待ちになる() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassComputerTurnThenComputerTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        let newState = try state.acceptPass()
        XCTAssertTrue(newState is ComputerInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
    }

    func test_パス了承待ちの時_モード切り替え不可能() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassComputerTurnThenComputerTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.changePlayerControl(of: .dark, to: .manual))
    }

    func test_パス了承待ちの時_リセット不可能() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassComputerTurnThenComputerTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.reset())
    }

    func test_パス了承待ちの時_セル描画完了不可能() throws {
        state = PassAcceptWaitingState(
            game: TestData.mustPassComputerTurnThenComputerTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        XCTAssertThrowsError(try state.finishUpdatingOneCell(isFinished: true))
    }
}
