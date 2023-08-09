//
//  ComputerInputWaitingStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxRelay
import RxTest
import RxSwift

final class ComputerInputWaitingStateTest: XCTestCase {
    private var state: ComputerInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
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

    func test_処理を実行すると_思考後置く位置が決まる() throws {
        state = ComputerInputWaitingState(
            game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game,
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

        XCTAssertEqual(game.events, [.next(1, TestData.startFromDarkComputerOnlyPlaceAt2_0.game)])
        XCTAssertEqual(computerProcessing.events, [
            .next(1, [true, false]),
            .next(1, [false, false]),
        ])
        XCTAssertEqual(finishComputerProcessing.events, [.next(1, Coordinate(x: 2, y: 0))])
    }

    func test_処理を実行し_思考完了前にリセットがかかっていると_ディスクは置かない() throws {
        state = ComputerInputWaitingState(
            game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                _ = self?.state.reset()
            default:
                self?.state.start()
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(game.events, [.next(2, TestData.startFromDarkComputerOnlyPlaceAt2_0.game)])
        XCTAssertEqual(computerProcessing.events, [
            .next(2, [true, false]),
        ])
        XCTAssertEqual(finishComputerProcessing.events.count, 0)
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

    func test_コンピューター入力待ちの時_コンピューター入力すると画面描画中になる() throws {
        state = ComputerInputWaitingState(
            game: TestData.startFromDarkComputerOnlyPlaceAt2_0.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output
        )
        let newState = try state.inputByComputer(coordinate: Coordinate(x: 2, y: 0))
        XCTAssertTrue(newState is UpdatingViewState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
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
