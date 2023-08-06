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

    // MARK: ゲーム読み込みが保存ゲームの有無で正しく分岐する

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

    // MARK: コンピューターの試行でセルの描画が正しく行われる

    func test_viewDidAppearが呼ばれるとゲームが開始され_コンピューターが思考しディスクを置き_セル2つの描画が更新され_描画が完了するとゲームが保存される() throws {
        fakeStrategy.fakeInput = TestData.startFromDarkComputerOnlyPlaceAt2_0.rawValue

        let computerProcessing = viewModel.computerProcessings.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let diskToPlace = viewModel.diskToPlace.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let playerControls = viewModel.playerControls.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let diskCounts = viewModel.diskCounts.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let message = viewModel.message.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let messageDiskSize = viewModel.messageDiskSize.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
            .next(4, (4)),
        ]).subscribe { [weak self] event in
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
            .next(1, [2, 2]),   // ゲーム読み込み後
            .next(4, [4, 1]),   // コンピューターがディスクを置いた後
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .dark, label: "'s turn")),   // ゲーム読み込み後
            .next(4, Message(disk: .light, label: "'s turn")),  // コンピューターがディスクを置いた後
        ])
        XCTAssertEqual(messageDiskSize.events, [
            .next(0, 0),    // 初期状態
            .next(1, 24),   // ゲーム読み込み後
        ])
        // 描画が最後まで完了していれば保存処理が走っている
        XCTAssertEqual(fakeStrategy.fakeOutput, "o10\nxxx---xo\n--------\n--------\n--------\n--------\n--------\n--------\n--------\n")
    }

    // MARK: ユーザーの試行でセルの描画が正しく行われる

    func test_白から始まる新規ゲームで_ユーザーが4_2にディスクを置くと_セル2つの描画が更新され_描画が完了するとゲームが保存される() throws {
        fakeStrategy.fakeInput = TestData.newGameStartFromLight.rawValue

        let computerProcessing = viewModel.computerProcessings.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let diskToPlace = viewModel.diskToPlace.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let playerControls = viewModel.playerControls.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let diskCounts = viewModel.diskCounts.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let message = viewModel.message.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let messageDiskSize = viewModel.messageDiskSize.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
            .next(4, (4)),
            .next(5, (5)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            case 3:
                self?.viewModel.didSelectCellAt(x: 4, y: 2) // (4, 2)に白を置き
            default:
                self?.viewModel.finishToPlace(isFinished: true) // 2つのセルの描画が終わる
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(computerProcessing.events, [
            .next(0, [false, false]),   // 初期状態
        ])
        // time > 1のイベントでフィルターすることで、ゲーム読み込み時の全セルの描画イベントを除く
        XCTAssertEqual(diskToPlace.events.filter { $0.time > 1 },[
            .next(3, DiskPlacement(disk: .light, coordinate: Coordinate(x: 4, y: 2), animated: true)),
            .next(4, DiskPlacement(disk: .light, coordinate: Coordinate(x: 4, y: 3), animated: true)),
        ])
        XCTAssertEqual(playerControls.events, [
            .next(0, [.manual, .manual]),   // 初期状態
        ])
        XCTAssertEqual(diskCounts.events, [
            .next(1, [2, 2]),   // ゲーム読み込み後
            .next(5, [1, 4]),   // ユーザーがディスクを置いた後
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .light, label: "'s turn")),   // ゲーム読み込み後
            .next(5, Message(disk: .dark, label: "'s turn")),  // ユーザーがディスクを置いた後
        ])
        XCTAssertEqual(messageDiskSize.events, [
            .next(0, 0),    // 初期状態
            .next(1, 24),   // ゲーム読み込み後
        ])
        // 描画が最後まで完了していれば保存処理が走っている
        XCTAssertEqual(fakeStrategy.fakeOutput, "x00\n--------\n--------\n----o---\n---oo---\n---xo---\n--------\n--------\n--------\n")
    }

    func test_ユーザーが置けないセルをタップしても何も起こらない() throws {
        fakeStrategy.fakeInput = TestData.newGameStartFromLight.rawValue

        let computerProcessing = viewModel.computerProcessings.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let diskToPlace = viewModel.diskToPlace.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let playerControls = viewModel.playerControls.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let diskCounts = viewModel.diskCounts.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let message = viewModel.message.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let messageDiskSize = viewModel.messageDiskSize.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.didSelectCellAt(x: 3, y: 2) // (3, 2)に白を置こうとするが何も起こらない
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(computerProcessing.events, [
            .next(0, [false, false]),   // 初期状態
        ])
        // time > 1のイベントでフィルターすることで、ゲーム読み込み時の全セルの描画イベントを除く
        XCTAssertEqual(diskToPlace.events.filter { $0.time > 1 }.count, 0)
        XCTAssertEqual(playerControls.events, [
            .next(0, [.manual, .manual]),   // 初期状態
        ])
        XCTAssertEqual(diskCounts.events, [
            .next(1, [2, 2]),   // ゲーム読み込み後
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .light, label: "'s turn")),   // ゲーム読み込み後
        ])
        XCTAssertEqual(messageDiskSize.events, [
            .next(0, 0),    // 初期状態
            .next(1, 24),   // ゲーム読み込み後
        ])
        // 保存処理は走らない
        XCTAssertEqual(fakeStrategy.fakeOutput, nil)
    }

    // MARK: パスの判定が正しくされ了承でターンが変わる

    func test_ディスクが置かれターンが変わった時_置く場所がないとアラートが表示され_了承するとターンが変わる() throws {
        fakeStrategy.fakeInput = TestData.mustPassOnNextTurn.rawValue

        let message = viewModel.message.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        let passAlert = viewModel.passAlert.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)

        // 描画完了を通知するタイミングはアサーション上重要ではないのでコントロールせず、即描画完了とする
        viewModel.diskToPlace.subscribe{ [weak self] _ in
            self?.viewModel.finishToPlace(isFinished: true)
        }.disposed(by: disposeBag)

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
            .next(4, (4)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            case 3:
                self?.viewModel.didSelectCellAt(x: 2, y: 0) // (2, 0)に黒を置くと白はどこにも置けなくなる
            default:
                self?.viewModel.pass()  // パスを了承すると黒のターンに変わる
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .dark, label: "'s turn")),   // ゲーム読み込み後
            .next(3, Message(disk: .light, label: "'s turn")),  // パスするアラートが表示されてる最中は白のターンと表示される
            .next(4, Message(disk: .dark, label: "'s turn")),   // パス後黒にターンが移る
        ])
        XCTAssertEqual(passAlert.events, [.next(3, PassAlert())])
        // 保存されるのは黒がディスクを置いて描画完了したところまで
        XCTAssertEqual(fakeStrategy.fakeOutput, "o00\nxxx-----\no-------\n--------\n--------\n--------\n--------\n--------\n--------\n")
    }

    // TODO: ゲーム読み込み時からパスが必要なケースは現状バグがある。他のテストを書き終わった後にテストを作成し、バグ修正する
}
