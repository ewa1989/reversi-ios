//
//  ViewModelTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/05.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxBlocking
import RxTest
import RxSwift
import RxCocoa

final class ViewModelTest: XCTestCase {
    private var viewModel: ViewModel<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
    private var fakeStrategy: FakeFileSaveAndLoadStrategy!
    private var dispatcher: SynchronousDispatcher!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUpWithError() throws {
        fakeStrategy = FakeFileSaveAndLoadStrategy()
        dispatcher = SynchronousDispatcher()
        viewModel = ViewModel(
            gameRepository: ReversiGameRepositoryImpl(strategy: fakeStrategy),
            dispatcher: dispatcher,
            initialDiskSize: 24
        )

        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: viewDidLoad

    func test_保存されたゲームがない時_画面ロード時に新ゲームが生成され_保存もされる() throws {
        let expected = ReversiGame.newGame()

        // 保存されたゲームを復元できない＝保存されたゲームがない
        fakeStrategy.fakeInput = ""

        viewModel.viewDidLoad()

        XCTAssertEqual(try viewModel.game.toBlocking().first(), expected)
        XCTAssertEqual(try FileParser.makeGameParsing(fakeStrategy.fakeOutput!), expected)
    }

    func test_保存されたゲームがある時_画面ロード時にロードされる() throws {
        let expected = TestData.darkSurroundedByLightGame.game

        fakeStrategy.fakeInput = TestData.darkSurroundedByLightGame.rawValue

        viewModel.viewDidLoad()

        XCTAssertEqual(try viewModel.game.toBlocking().first(), expected)
    }

    // MARK: viewDidAppear

    func test_viewDidAppearが呼ばれるとゲームが開始され_コンピューターが思考しディスクを置き_セル2つの描画が更新され_描画が完了するとゲームが保存される() throws {
        fakeStrategy.fakeInput = TestData.startFromDarkComputerOnlyPlaceAt2_0.rawValue

        let computerProcessing = scheduler.createObserver([Bool].self)
        viewModel.computerProcessings
            .bind(to: computerProcessing)
            .disposed(by: disposeBag)

        let diskToPlace = scheduler.createObserver(DiskPlacement.self)
        viewModel.diskToPlace
            .bind(to: diskToPlace)
            .disposed(by: disposeBag)

        let playerControls = scheduler.createObserver([Player].self)
        viewModel.playerControls
            .bind(to: playerControls)
            .disposed(by: disposeBag)

        let diskCounts = scheduler.createObserver([Int].self)
        viewModel.diskCounts
            .bind(to: diskCounts)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
            .next(4, (4)),
        ]).subscribe { [weak self] event in
            print("\(event)")
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.finishToPlace(isFinished: true) // 1つ目と2つ目のセル(2, 0)の描画が終わる
            }
        }.disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(computerProcessing.events, [
            .next(0, [false, false]),   // 初期状態
            .next(2, [true, false]),    // コンピューター思考開始
            .next(2, [false, false])    // コンピューター思考終了
        ])
        // time > 1のイベントでフィルターすることで、ゲーム読み込み時の全セルの描画イベントを除く
        XCTAssertEqual(diskToPlace.events.filter { $0.time > 1 },[
            .next(2, DiskPlacement(disk: .dark, coordinate: Coordinate(x: 2, y: 0), animated: true)),
            .next(3, DiskPlacement(disk: .dark, coordinate: Coordinate(x: 1, y: 0), animated: true)),
        ])
        XCTAssertEqual(playerControls.events, [
            .next(0, [.manual, .manual]),   // 初期状態
            .next(1, [.computer, .manual]), // ゲーム読み込み後
        ])
        XCTAssertEqual(diskCounts.events, [
            .next(1, [2, 2]),   // 初期状態
            .next(4, [4, 1]),   // コンピューターがディスクを置いた後
        ])
        // 描画が最後まで完了していれば保存処理が走っている
        XCTAssertEqual(fakeStrategy.fakeOutput, "o10\nxxx---xo\n--------\n--------\n--------\n--------\n--------\n--------\n--------\n")
    }
}
