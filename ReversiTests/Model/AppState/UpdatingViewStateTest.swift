//
//  UpdatingViewStateTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxRelay
import RxTest
import RxSwift

final class UpdatingViewStateTest: XCTestCase {
    private var state: UpdatingViewState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
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

    func test_画面描画中の処理を実行すると_画面描画情報が通知される() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [
                DiskPlacement(disk: .dark, coordinate: Coordinate(x: 0, y: 0), animated: true),
                DiskPlacement(disk: .dark, coordinate: Coordinate(x: 1, y: 0), animated: true),
            ],
            isReset: false,
            forLoading: false
        )

        scheduler.createColdObservable([
            .next(1, (1)),
        ]).subscribe { [weak self] _ in
            self?.state.start(viewHasAppeared: true)
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(diskToPlace.events, [.next(1, DiskPlacement(disk: .dark, coordinate: Coordinate(x: 0, y: 0), animated: true))])
    }

    func test_画面描画中の処理を実行し_画面描画完了前にリセットがかかると_画面描画情報が通知されない() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [
                DiskPlacement(disk: .dark, coordinate: Coordinate(x: 0, y: 0), animated: true),
                DiskPlacement(disk: .dark, coordinate: Coordinate(x: 1, y: 0), animated: true),
            ],
            isReset: false,
            forLoading: false
        )

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                _ = try! self?.state.reset()
            default:
                self?.state.start(viewHasAppeared: true)
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(diskToPlace.events.count, 0)
    }

    func test_画面描画中の時_ユーザー入力不可能() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)],
            isReset: false,
            forLoading: false
        )
        XCTAssertThrowsError(try state.inputByUser(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_画面描画中の時_コンピューター入力不可能() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)],
            isReset: false,
            forLoading: false
        )
        XCTAssertThrowsError(try state.inputByComputer(coordinate: Coordinate(x: 0, y: 0)))
    }

    func test_画面描画中の時_パス了承不可能() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)],
            isReset: false,
            forLoading: false
        )
        XCTAssertThrowsError(try state.acceptPass())
    }

    func test_画面描画中の時_モード切り替えると画面描画中継続し_保存されない() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)],
            isReset: false,
            forLoading: false
        )
        let newState = try state.changePlayerControl(of: .dark, to: .computer)
        XCTAssertTrue(newState is UpdatingViewState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
        XCTAssertNil(strategy.fakeOutput)
    }

    func test_画面描画中の時_リセットすると画面描画中継続() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: nil, coordinate: Coordinate(x: 0, y: 0), animated: false)],
            isReset: false,
            forLoading: false
        )
        let newState = try state.reset()
        XCTAssertTrue(newState is UpdatingViewState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
    }

    func test_画面描画中の時_描画対象がまだあると_セル描画完了後画面描画中継続し_保存されない() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [DiskPlacement(disk: .dark, coordinate: Coordinate(x: 1, y: 0), animated: true)],
            isReset: false,
            forLoading: false
        )
        let newState = try state.finishUpdatingOneCell(isFinished: true)
        XCTAssertTrue(newState is UpdatingViewState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
        XCTAssertNil(strategy.fakeOutput)
    }

    func test_リセットによる画面描画中の時_描画対象がないと_セル描画完了後gameの状態がそのまま保存される() throws {
        state = UpdatingViewState(
            game: TestData.newGame.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [],
            isReset: true,
            forLoading: false
        )
        let newState = try state.finishUpdatingOneCell(isFinished: true)
        XCTAssertTrue(newState is UserInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
        XCTAssertEqual(strategy.fakeOutput, TestData.newGame.rawValue)
    }

    func test_ディスク配置による画面描画中の時_描画対象がなく次に手動で打つ手があると_セル描画完了後_ターンが代わりユーザー入力待ちになり_保存される() throws {
        state = UpdatingViewState(
            game: TestData.willDrawOnNextTurn.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [],
            isReset: false,
            forLoading: false
        )
        let newState = try state.finishUpdatingOneCell(isFinished: true)
        XCTAssertTrue(newState is UserInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
        XCTAssertEqual(strategy.fakeOutput, "x00\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoox-\n")
    }

    func test_ディスク配置による画面描画中の時_描画対象がなく次にコンピューターで打つ手があると_セル描画完了後_ターンが変わりコンピューター入力待ちになり_保存される() throws {
        state = UpdatingViewState(
            game: TestData.newGameStartFromBothComputer.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [],
            isReset: false,
            forLoading: false
        )
        let newState = try state.finishUpdatingOneCell(isFinished: true)
        XCTAssertTrue(newState is ComputerInputWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
        XCTAssertEqual(strategy.fakeOutput, "o11\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n")
    }

    func test_ディスク配置による画面描画中の時_描画対象がなく次に打つ手がないと_セル描画完了後_ターンが変わりパス了承待ちになり_保存される() throws {
        state = UpdatingViewState(
            game: TestData.darkSurroundedByLightGame.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [],
            isReset: false,
            forLoading: false
        )
        let newState = try state.finishUpdatingOneCell(isFinished: true)
        XCTAssertTrue(newState is PassAcceptWaitingState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
        XCTAssertEqual(strategy.fakeOutput, "o00\n--------\n-ooo----\n-oxo----\n-ooo----\n--------\n--------\n--------\n--------\n")
    }

    func test_ディスク配置による画面描画中の時_描画対象がなくどちらも打つ手がないと_セル描画完了後_ターンが変わりゲーム終了になり_保存される() throws {
        state = UpdatingViewState(
            game: TestData.unfinishedButNowhereToPlace.game,
            repository: repository,
            dispatcher: dispatcher,
            output: output,
            updates: [],
            isReset: false,
            forLoading: false
        )
        let newState = try state.finishUpdatingOneCell(isFinished: true)
        XCTAssertTrue(newState is GameFinishedState<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>)
        XCTAssertEqual(strategy.fakeOutput, "-00\nxxxxx---\nxxxxx---\nxxxxx---\nxxxxx---\nxxxxx---\n--------\n--------\n--------\n")
    }
}
