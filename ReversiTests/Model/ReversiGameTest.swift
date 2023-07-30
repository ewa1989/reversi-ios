//
//  ReversiGameTest.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/07/30.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import XCTest

final class ReversiGameTest: XCTestCase {
    private var game: ReversiGame!

    override func setUpWithError() throws {
        game = ReversiGame()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: setDisk, diskAt, countDisks

    func test_白のディスクをボードの一番先頭に置ける() throws {
        XCTAssertEqual(game.board.countDisks(of: .light), 0)

        game.board.setDisk(.light, atX: 0, y: 0)

        XCTAssertEqual(game.board.countDisks(of: .light), 1)
        XCTAssertEqual(game.board.diskAt(x: 0, y: 0), .light)
    }

    func test_黒のディスクをボードの一番末尾に置ける() throws {
        XCTAssertEqual(game.board.countDisks(of: .light), 0)

        game.board.setDisk(.dark, atX: 7, y: 7)

        XCTAssertEqual(game.board.countDisks(of: .dark), 1)
        XCTAssertEqual(game.board.diskAt(x: 7, y: 7), .dark)
    }

    // MARK: sideWithMoreDisks

    func test_黒のディスクが1つ置かれているとディスクの枚数が多いのは黒() throws {
        game.board.setDisk(.dark, atX: 0, y: 0)

        XCTAssertEqual(game.board.sideWithMoreDisks(), .dark)
    }

    func test_白のディスクが1つ置かれているとディスクの枚数が多いのは白() throws {
        game.board.setDisk(.light, atX: 0, y: 0)

        XCTAssertEqual(game.board.sideWithMoreDisks(), .light)
    }

    func test_左半分に黒_右半分に白のディスクが置かれていると引き分け() throws {
        let tiedGame = tiedComputerMatchWithLeftSideDarkAndRightSideLightBoard()

        XCTAssertNil(tiedGame.board.sideWithMoreDisks())
    }

    // MARK: flippedDiskCoordinatesByPlacingDiskの各方向
    // 以下の盤面a~hの位置に黒を置いた時に裏返るディスクの位置をテストする
    // 01234567x/y
    // e-f-g---0
    // -ooo----1
    // doxoh---2
    // -ooo----3
    // c-b-a---4
    // --------5
    // --------6
    // --------7

    func test_黒が白に囲まれた盤面で_右下に黒を置くと_置いた左上方向のディスクが裏返る() throws {
        let expected = [(3, 3)].toCoordinates()

        let game = darkSurroundedByLightGame()
        let actual = game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 4, y: 4)

        XCTAssertEqual(actual, expected)
    }

    func test_黒が白に囲まれた盤面で_下に黒を置くと_置いた上方向のディスクが裏返る() throws {
        let expected = [(2, 3)].toCoordinates()

        let game = darkSurroundedByLightGame()
        let actual = game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 2, y: 4)

        XCTAssertEqual(actual, expected)
    }

    func test_黒が白に囲まれた盤面で_左下に黒を置くと_置いた右上方向のディスクが裏返る() throws {
        let expected = [(1, 3)].toCoordinates()

        let game = darkSurroundedByLightGame()
        let actual = game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 0, y: 4)

        XCTAssertEqual(actual, expected)
    }

    func test_黒が白に囲まれた盤面で_左に黒を置くと_置いた右方向のディスクが裏返る() throws {
        let expected = [(1, 2)].toCoordinates()

        let game = darkSurroundedByLightGame()
        let actual = game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 0, y: 2)

        XCTAssertEqual(actual, expected)
    }

    func test_黒が白に囲まれた盤面で_左上に黒を置くと_置いた右下方向のディスクが裏返る() throws {
        let expected = [(1, 1)].toCoordinates()

        let game = darkSurroundedByLightGame()
        let actual = game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 0, y: 0)

        XCTAssertEqual(actual, expected)
    }

    func test_黒が白に囲まれた盤面で_上に黒を置くと_置いた下方向のディスクが裏返る() throws {
        let expected = [(2, 1)].toCoordinates()

        let game = darkSurroundedByLightGame()
        let actual = game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 2, y: 0)

        XCTAssertEqual(actual, expected)
    }

    func test_黒が白に囲まれた盤面で_右上に黒を置くと_置いた左下方向のディスクが裏返る() throws {
        let expected = [(3, 1)].toCoordinates()

        let game = darkSurroundedByLightGame()
        let actual = game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 4, y: 0)

        XCTAssertEqual(actual, expected)
    }

    func test_黒が白に囲まれた盤面で_右に黒を置くと_置いた左方向のディスクが裏返る() throws {
        let expected = [(3, 2)].toCoordinates()

        let game = darkSurroundedByLightGame()
        let actual = game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 4, y: 2)

        XCTAssertEqual(actual, expected)
    }

    // MARK: flippedDiskCoordinatesByPlacingDiskの返す順番

    func test_一方向で複数枚裏返る場合に_置いたディスクに近いセルから順になったコレクションが返ってくる() throws {
        let expected = [(2, 0), (1, 0)].toCoordinates()

        var game = ReversiGame.newGame()
        game.board.setDisk(.light, atX: 0, y: 0)
        game.board.setDisk(.dark, atX: 1, y: 0)
        game.board.setDisk(.dark, atX: 2, y: 0)

        let actual = game.board.flippedDiskCoordinatesByPlacingDisk(.light, atX: 3, y: 0)

        XCTAssertEqual(actual, expected)
    }
}
