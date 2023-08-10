//
//  UserInputWaitingStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxRelay
import RxTest
import RxSwift

final class UserInputWaitingStateTest: XCTestCase {
    private var state: UserInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
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

        state = UserInputWaitingState(
            game: TestData.newGame.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_ユーザー入力待ちの処理を実行すると_ゲームの状態が通知される() throws {
        scheduler.createColdObservable([
            .next(1, (1)),
        ]).subscribe { [weak self] _ in
            self?.state.start()
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(game.events, [.next(1, TestData.newGame.game)])
    }

    func test_ユーザー入力待ちの時_ディスクを置ける位置にユーザー入力すると_画面描画中になる() throws {
        let newState = try state.inputByUser(coordinate: Coordinate(x: 3, y: 2))
        XCTAssertTrue(newState is UpdatingViewState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
    }

    func test_ユーザー入力待ちの時_ディスクを置けない位置にユーザー入力すると_DiskPlacementErrorが投げられる() throws {
        XCTAssertThrowsError(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_ユーザー入力待ちの時_コンピューター入力不可能() throws {
        XCTAssertThrowsError(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_ユーザー入力待ちの時_パス了承不可能() throws {
        XCTAssertThrowsError(try state.acceptPass())
    }

    func test_ユーザー入力待ちの時_待ち手のモード切り替えするとユーザー入力待ち継続し_保存される() throws {
        let newState = try state.changePlayerControl(of: .light, to: .computer)
        XCTAssertTrue(newState is UserInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
        XCTAssertEqual(strategy.fakeOutput, "x01\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n")
    }

    func test_コンピューター入力待ちの時_攻め手のモード切り替えするとコンピューター入力待ちになり_保存される() throws {
        let newState = try state.changePlayerControl(of: .dark, to: .computer)
        XCTAssertTrue(newState is ComputerInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
        XCTAssertEqual(strategy.fakeOutput, "x10\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n")
    }

    func test_ユーザー入力待ちの時_リセットすると画面描画中になる() throws {
        let newState = try state.reset()
        XCTAssertTrue(newState is UpdatingViewState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
    }

    func test_ユーザー入力待ちの時_セル描画完了不可能() throws {
        XCTAssertThrowsError(try state.finishUpdatingOneCell(isFinished: true))
    }
}
