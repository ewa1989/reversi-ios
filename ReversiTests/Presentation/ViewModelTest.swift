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

final class SynchronousDispatchViewModelTest: XCTestCase {
    private var viewModel: ViewModel<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
    private var fakeStrategy: FakeFileSaveAndLoadStrategy!
    private var dispatcher: SynchronousDispatcher!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    private var computerProcessing: TestableObserver<[Bool]>!
    private var diskToPlace: TestableObserver<DiskPlacement>!
    private var playerControls: TestableObserver<[Player]>!
    private var diskCounts: TestableObserver<[Int]>!
    private var message: TestableObserver<Message>!
    private var messageDiskSize: TestableObserver<CGFloat>!
    private var passAlert: TestableObserver<PassAlert>!

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

        computerProcessing = viewModel.computerProcessings.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        diskToPlace = viewModel.diskToPlace.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        playerControls = viewModel.playerControls.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        diskCounts = viewModel.diskCounts.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        message = viewModel.message.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        messageDiskSize = viewModel.messageDiskSize.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        passAlert = viewModel.passAlert.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
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

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
            .next(4, (4)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
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
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            case 3:
                self?.viewModel.didSelectCellAt(x: 4, y: 2) // (4, 2)に白を置き
            default:
                self?.viewModel.finishToPlace(isFinished: true) // 2つのセルの描画が終わる
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        // time > 1のイベントでフィルターすることで、ゲーム読み込み時の全セルの描画イベントを除く
        XCTAssertEqual(diskToPlace.events.filter { $0.time > 1 },[
            .next(3, DiskPlacement(disk: .light, coordinate: Coordinate(x: 4, y: 2), animated: true)),
            .next(4, DiskPlacement(disk: .light, coordinate: Coordinate(x: 4, y: 3), animated: true)),
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
        // 描画が最後まで完了していれば保存処理が走っている
        XCTAssertEqual(fakeStrategy.fakeOutput, "x00\n--------\n--------\n----o---\n---oo---\n---xo---\n--------\n--------\n--------\n")
    }

    func test_ユーザーが置けないセルをタップしても何も起こらない() throws {
        fakeStrategy.fakeInput = TestData.newGameStartFromLight.rawValue

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.didSelectCellAt(x: 3, y: 2) // (3, 2)に白を置こうとするが何も起こらない
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        // time > 1のイベントでフィルターすることで、ゲーム読み込み時の全セルの描画イベントを除く
        XCTAssertEqual(diskToPlace.events.filter { $0.time > 1 }.count, 0)
        XCTAssertEqual(diskCounts.events, [
            .next(1, [2, 2]),   // ゲーム読み込み後
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .light, label: "'s turn")),   // ゲーム読み込み後
        ])
        // 保存処理は走らない
        XCTAssertEqual(fakeStrategy.fakeOutput, nil)
    }

    func test_すでに置いてあるセルをタップしても何も起こらない() throws {
        fakeStrategy.fakeInput = TestData.blankSurroundedByLightSurroundingByDark.rawValue

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.didSelectCellAt(x: 2, y: 1) // すでにディスクがある(2, 1)に黒を置こうとするが何も起こらない
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        // time > 1のイベントでフィルターすることで、ゲーム読み込み時の全セルの描画イベントを除く
        XCTAssertEqual(diskToPlace.events.filter { $0.time > 1 }.count, 0)
        XCTAssertEqual(diskCounts.events, [
            .next(1, [16, 8]),   // ゲーム読み込み後
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .dark, label: "'s turn")),   // ゲーム読み込み後
        ])
        // 保存処理は走らない
        XCTAssertEqual(fakeStrategy.fakeOutput, nil)
    }

    // MARK: パスの判定が正しくされ了承でターンが変わる

    func test_ディスクが置かれターンが変わった時_置く場所がないとアラートが表示され_了承するとターンが変わる() throws {
        fakeStrategy.fakeInput = TestData.mustPassOnNextTurn.rawValue

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
            .next(4, (4)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            case 3:
                self?.viewModel.didSelectCellAt(x: 2, y: 0) // (2, 0)に黒を置くと白はどこにも置けなくなる
                self?.viewModel.finishUpdatingCells(times: 2)
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

    func test＿ゲーム読み込み時から先手がパスが必要な場合_表示直後にパスするアラートが表示され_パスを了承しても保存はされない() throws {
        fakeStrategy.fakeInput = TestData.mustPassOnThisTurn.rawValue

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.pass()  // どこにも置けずパスすると黒のターンに変わる
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .light, label: "'s turn")),   // ゲーム読み込み後、パスするアラートが表示されてる最中は白のターンと表示される
            .next(3, Message(disk: .dark, label: "'s turn")),  // パスすると黒にターンが移る
        ])
        XCTAssertEqual(passAlert.events, [.next(2, PassAlert())])
        // パスするアラート表示、パス了承では保存はされない
        XCTAssertEqual(fakeStrategy.fakeOutput, nil)
    }

    // MARK: ゲームの終了判定が正しく行われる

    func test_置く場所がどちらもなくなり_ゲーム終了と判定され_保存される() {
        fakeStrategy.fakeInput = TestData.blankSurroundedByLightSurroundingByDark.rawValue

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.didSelectCellAt(x: 2, y: 2) // 黒が(2, 2)に置くと白が8枚裏返り全て黒になる
                self?.viewModel.finishUpdatingCells(times: 9)
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(diskCounts.events, [
            .next(1, [16, 8]),   // ゲーム読み込み後
            .next(3, [25, 0])   // ゲーム終了時
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .dark, label: "'s turn")),   // ゲーム読み込み後
            .next(3, Message(disk: .dark, label: " won")),   // ゲーム終了時
        ])
        XCTAssertEqual(fakeStrategy.fakeOutput, "-00\nxxxxx---\nxxxxx---\nxxxxx---\nxxxxx---\nxxxxx---\n--------\n--------\n--------\n")
    }

    func test_全セルが埋まり_ゲーム終了引き分けと判定され_保存される() {
        fakeStrategy.fakeInput = TestData.willDrawOnNextTurn.rawValue

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.didSelectCellAt(x: 7, y: 7) // 白が(7, 7)に置くと黒が1枚裏返り、左半分が黒、右半分が白になる
                self?.viewModel.finishUpdatingCells(times: 2)
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(diskCounts.events, [
            .next(1, [33, 30]),   // ゲーム読み込み後
            .next(3, [32, 32])   // ゲーム終了時
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .light, label: "'s turn")),   // ゲーム読み込み後
            .next(3, Message(disk: nil, label: "Tied")),   // ゲーム終了時
        ])
        XCTAssertEqual(messageDiskSize.events, [
            .next(0, 0),    // 初期状態
            .next(1, 24),   // ゲーム読み込み後
            .next(3, 0),   // ゲーム終了時
        ])
        XCTAssertEqual(fakeStrategy.fakeOutput, "-00\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\n")
    }

    // MARK: プレイヤーモード変更

    func test_進行中のゲームで_ManualからComputerにモードを変更すると_状態が保存される() throws {
        fakeStrategy.fakeInput = TestData.newGame.rawValue

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.changePlayerControl(of: .light, to: .computer)  // 白のモードをComputerにすると状態が保存される
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(playerControls.events, [
            .next(0, [.manual, .manual]),   // 初期状態
            .next(3, [.manual, .computer]), // モード変更後
        ])
        XCTAssertEqual(fakeStrategy.fakeOutput, "x01\n--------\n--------\n--------\n---ox---\n---xo---\n--------\n--------\n--------\n")
    }

    func test_終了しているゲームで_ComputerからManualにモードを変更すると_状態が保存される() throws {
        fakeStrategy.fakeInput = TestData.tiedComputerMatchWithLeftSideDarkAndRightSideLightBoard.rawValue

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.changePlayerControl(of: .dark, to: .manual)  // 黒のモードをManualにすると状態が保存される
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(playerControls.events, [
            .next(0, [.manual, .manual]),   // 初期状態
            .next(1, [.computer, .computer]),   // ゲーム読み込み後
            .next(3, [.manual, .computer]), // モード変更後
        ])
        XCTAssertEqual(fakeStrategy.fakeOutput, "-01\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\nxxxxoooo\n")
    }

    // MARK: リセット

    func test_進行中のゲームを_リセットすると初期状態に戻り_保存もされる() throws {
        fakeStrategy.fakeInput = TestData.darkSurroundedByLightGame.rawValue

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.reset() // リセット
                self?.viewModel.finishUpdatingCells()
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        // リセット時全セルの再描画がかかっている
        XCTAssertEqual(diskToPlace.events.filter { $0.time == 3 }.count, 64)
        XCTAssertEqual(diskCounts.events, [
            .next(1, [1, 8]),   // ゲーム読み込み後
            .next(3, [2, 2]),   // リセット後
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .dark, label: "'s turn")),   // ゲーム読み込み後
        ])
        XCTAssertEqual(fakeStrategy.fakeOutput, TestData.newGame.rawValue)
    }

    func test_引き分け終了しているゲームを_リセットすると初期状態に戻り_保存もされる() throws {
        fakeStrategy.fakeInput = TestData.tiedComputerMatchWithLeftSideDarkAndRightSideLightBoard.rawValue

        scheduler.createColdObservable([
            .next(1, (1)),
            .next(2, (2)),
            .next(3, (3)),
        ]).subscribe { [weak self] event in
            switch event.element {
            case 1:
                self?.viewModel.viewDidLoad()   // ViewControllerが読み込まれ
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                self?.viewModel.reset() // リセット
                self?.viewModel.finishUpdatingCells()
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        // リセット時全セルの再描画がかかっている
        XCTAssertEqual(diskToPlace.events.filter { $0.time == 3 }.count, 64)
        XCTAssertEqual(playerControls.events, [
            .next(0, [.manual, .manual]),   // 初期状態
            .next(1, [.computer, .computer]),   // ゲーム読み込み後
            .next(3, [.manual, .manual])    // リセット後
        ])
        XCTAssertEqual(diskCounts.events, [
            .next(1, [32, 32]),   // ゲーム読み込み後
            .next(3, [2, 2]),   // リセット後
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(3, Message(disk: .dark, label: "'s turn")),   // リセット後
        ])
        XCTAssertEqual(messageDiskSize.events, [
            .next(0, 0),    // 初期状態
            .next(3, 24),   // リセット後
        ])
        XCTAssertEqual(fakeStrategy.fakeOutput, TestData.newGame.rawValue)
    }

    // MARK: 処理キャンセル

    func test_裏返し中のリセット() throws {
        fakeStrategy.fakeInput = TestData.blankSurroundedByLightSurroundingByDark.rawValue

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
                self?.viewModel.finishUpdatingCells()
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            case 3:
                self?.viewModel.didSelectCellAt(x: 2, y: 2) // (2, 2)に黒を置くと置いた1枚＋裏返る8枚の計9枚の再描画が始まる
                self?.viewModel.finishToPlace(isFinished: true) // 2枚目まで描画させる
            case 4:
                self?.viewModel.reset() // 3枚目の描画中にリセット
            default:
                self?.viewModel.finishUpdatingCells()
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        // ディスクを置いたことによる描画は2枚目で止まっている
        XCTAssertEqual(diskToPlace.events.filter { $0.time == 3 }.count, 2)
        // リセットによる描画は全セル行われている
        XCTAssertEqual(diskToPlace.events.filter { $0.time > 3 }.count, 64)
        XCTAssertEqual(diskCounts.events, [
            .next(1, [16, 8]),   // ゲーム読み込み後
            .next(5, [2, 2]),   // リセット時
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .dark, label: "'s turn")),   // ゲーム読み込み後
        ])
        XCTAssertEqual(fakeStrategy.fakeOutput, TestData.newGame.rawValue)
    }
}

final class DispatchTimingControlledViewModelTest: XCTestCase {
    private var viewModel: ViewModel<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, TimingControllableDispatcher>!
    private var fakeStrategy: FakeFileSaveAndLoadStrategy!
    private var dispatcher: TimingControllableDispatcher!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    private var computerProcessing: TestableObserver<[Bool]>!
    private var diskToPlace: TestableObserver<DiskPlacement>!
    private var playerControls: TestableObserver<[Player]>!
    private var diskCounts: TestableObserver<[Int]>!
    private var message: TestableObserver<Message>!

    override func setUpWithError() throws {
        fakeStrategy = FakeFileSaveAndLoadStrategy()
        dispatcher = TimingControllableDispatcher()
        viewModel = ViewModel(
            gameRepository: ReversiGameRepositoryImpl(strategy: fakeStrategy),
            dispatcher: dispatcher,
            initialDiskSize: 24
        )

        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        computerProcessing = viewModel.computerProcessings.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        diskToPlace = viewModel.diskToPlace.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        playerControls = viewModel.playerControls.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        diskCounts = viewModel.diskCounts.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
        message = viewModel.message.makeTestableObserver(testScheduler: scheduler, disposeBag: disposeBag)
    }

    func test_コンピューターの思考中に_モードをManualに変更すると_ターンは変わらなず_保存されている() {
        fakeStrategy.fakeInput = TestData.startFromDarkComputerOnlyPlaceAt2_0.rawValue

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
                self?.viewModel.finishUpdatingCells() {
                    self?.dispatcher.work?()
                    self?.dispatcher.work = nil
                }
            case 2:
                self?.viewModel.viewDidAppear() // ViewControllerが表示され
            default:
                // dispatcher.workを実行する前にchangePlayerControlを呼ぶことで、コンピューターの思考中にモードを切り替えたことを再現する
                self?.viewModel.changePlayerControl(of: .dark, to: .manual) // 黒のモードをManualに変更する
            }
        }.disposed(by: disposeBag)
        scheduler.start()

        XCTAssertEqual(computerProcessing.events, [
            .next(0, [false, false]),   // 初期状態
            .next(2, [true, false]),   // コンピューター思考開始
            .next(3, [false, false])    // モード変更後
        ])
        // time > 1のイベントでフィルターすることで、ゲーム読み込み時の全セルの描画イベントを除く
        XCTAssertEqual(diskToPlace.events.filter { $0.time > 1 }.count, 0)
        XCTAssertEqual(playerControls.events, [
            .next(0, [.manual, .manual]),   // 初期状態
            .next(1, [.computer, .manual]),   // ゲーム読み込み後
            .next(3, [.manual, .manual]),   // 初期状態
        ])
        XCTAssertEqual(diskCounts.events, [
            .next(1, [2, 2]),   // ゲーム読み込み後
        ])
        XCTAssertEqual(message.events, [
            .next(0, Message(disk: nil, label: "Tied")),        // 初期状態
            .next(1, Message(disk: .dark, label: "'s turn")),   // ゲーム読み込み後
        ])
        XCTAssertEqual(fakeStrategy.fakeOutput, "x00\nxo----xo\n--------\n--------\n--------\n--------\n--------\n--------\n--------\n")
    }
}

// MARK: Helper

private extension ViewModel {
    /// 読み込み・リセット時最初に描画される1セルと残り63セルを描画するため64回描画完了を通知する。
    /// - Parameter onEveryBeginning: 毎回描画完了通知に先立って実行する。
    func finishUpdatingCells(times: Int = 64, onEveryBeginning: (() -> Void)? = nil) {
        (0..<times).forEach { [weak self] _ in
            onEveryBeginning?()
            self?.finishToPlace(isFinished: true)
        }
    }
}
