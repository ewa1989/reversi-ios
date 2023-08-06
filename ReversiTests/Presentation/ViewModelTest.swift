//
//  ViewModelTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/05.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest
import RxBlocking

final class ViewModelTest: XCTestCase {
    private var viewModel: ViewModel<ReversiGameRepositoryImpl<FakeFileSaveAndLoadStrategy>, SynchronousDispatcher>!
    private var fakeStrategy: FakeFileSaveAndLoadStrategy!
    private var dispatcher: SynchronousDispatcher!

    override func setUpWithError() throws {
        fakeStrategy = FakeFileSaveAndLoadStrategy()
        dispatcher = SynchronousDispatcher()
        viewModel = ViewModel(
            gameRepository: ReversiGameRepositoryImpl(strategy: fakeStrategy),
            dispatcher: dispatcher,
            initialDiskSize: 24
        )
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_保存されたゲームがない時_画面ロード時に新ゲームが生成され_保存もされる() throws {
        let expected = ReversiGame.newGame()

        // 保存されたゲームを復元できない＝保存されたゲームがない
        fakeStrategy.fakeInput = ""

        viewModel.viewDidLoad()

        XCTAssertEqual(try viewModel.game.toBlocking().first(), expected)
        XCTAssertEqual(try FileParser.makeGameParsing(fakeStrategy.fakeOutput!), expected)
    }
}
