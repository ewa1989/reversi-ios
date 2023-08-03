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

    // MARK: setDisk, diskAt, countDisks, diskCounts

    func test_白のディスクをボードの一番先頭に置ける() throws {
        XCTAssertEqual(game.board.countDisks(of: .light), 0)

        game.board.setDisk(.light, atX: 0, y: 0)

        XCTAssertEqual(game.board.countDisks(of: .light), 1)
        XCTAssertEqual(game.board.diskAt(x: 0, y: 0), .light)
        XCTAssertEqual(game.board.diskCounts, [0, 1])
    }

    func test_黒のディスクをボードの一番末尾に置ける() throws {
        XCTAssertEqual(game.board.countDisks(of: .dark), 0)

        game.board.setDisk(.dark, atX: 7, y: 7)

        XCTAssertEqual(game.board.countDisks(of: .dark), 1)
        XCTAssertEqual(game.board.diskAt(x: 7, y: 7), .dark)
        XCTAssertEqual(game.board.diskCounts, [1, 0])
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

    // 以下の盤面（1~8は白）で#に黒を置いた時に1~8の順になったコレクションが正しい
    // xxxxx---
    // x123x---
    // x8#4x---
    // x765x---
    // xxxxx---
    // --------
    // --------
    // --------
    func test_複数枚裏返る場合に_左上から時計回り順になったコレクションが返ってくる() throws {
        let expected = [
            (1, 1),
            (2, 1),
            (3, 1),
            (3, 2),
            (3, 3),
            (2, 3),
            (1, 3),
            (1, 2),
        ].toCoordinates()

        let game = blankSurroundedByLightSurroundingByDark()
        let actual = game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 2, y: 2)

        XCTAssertEqual(actual, expected)
    }

    // MARK: flippedDiskCoordinatesByPlacingDiskの裏返らない場合

    func test_初期盤面で黒をセルx4_y2に置いても1枚も裏返らない() throws {
        let game = ReversiGame.newGame()
        XCTAssertTrue(game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 4, y: 2).isEmpty)
    }

    func test_すでにディスクが存在するセルには置けない() throws {
        var game = ReversiGame.newGame()
        game.board.setDisk(.light, atX: 3, y: 2)

        XCTAssertTrue(game.board.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 3, y: 2).isEmpty)
    }

    // MARK: validMoves

    func test_初期盤面で黒は4箇所置くことができる() throws {
        let expected = [
            (3, 2),
            (2, 3),
            (5, 4),
            (4, 5),
        ].toCoordinates()

        let newGame = ReversiGame.newGame()
        let actual = newGame.board.validMoves(for: .dark)

        XCTAssertEqual(actual, expected)
    }

    func test_1つもディスクがない盤面では黒も白もどこに置いても1つも裏返らないので置くことができない() throws {
        let noDiskGame = ReversiGame()
        XCTAssertTrue(noDiskGame.board.validMoves(for: .dark).isEmpty)
        XCTAssertTrue(noDiskGame.board.validMoves(for: .light).isEmpty)
    }

    func test_全て埋まった盤面では黒も白もどこにも置くことができない() throws {
        let allCellFilledGame = tiedComputerMatchWithLeftSideDarkAndRightSideLightBoard()
        XCTAssertTrue(allCellFilledGame.board.validMoves(for: .dark).isEmpty)
        XCTAssertTrue(allCellFilledGame.board.validMoves(for: .light).isEmpty)
    }

    // MARK: state

    func test_黒で始まる初期盤面は黒のターン() throws {
        let newGame = ReversiGame.newGame()
        XCTAssertEqual(newGame.state, .move(side: .dark))
    }

    func test_白で始まる初期盤面は白のターン() throws {
        let newGameStartFromLight = newGameStartFromLight()
        XCTAssertEqual(newGameStartFromLight.state, .move(side: .light))
    }

    func test_終了したゲームでディスク数が等しければ引き分け() throws {
        let tiedGame = tiedComputerMatchWithLeftSideDarkAndRightSideLightBoard()
        XCTAssertEqual(tiedGame.state, .draw)
    }

    func test_test_終了したゲームで黒のディスクが多ければ黒の勝利() throws {
        let winnerDarkGame = allDarkBoard()
        XCTAssertEqual(winnerDarkGame.state, .win(winner: .dark))
    }

    func test_test_終了したゲームで白のディスクが多ければ白の勝利() throws {
        let winnerLightGame = allLightBoard()
        XCTAssertEqual(winnerLightGame.state, .win(winner: .light))
    }

    // MARK: canPlaceAnyDisks

    func test_ゲーム初期状態だと黒白どちらもディスクを置く位置がある() throws {
        let newGame = ReversiGame.newGame()

        XCTAssertTrue(newGame.board.canPlaceAnyDisks(by: .dark))
        XCTAssertTrue(newGame.board.canPlaceAnyDisks(by: .light))
    }

    func test_黒が白に囲まれたゲームだと黒だけ置く位置がある() throws {
        let game = darkSurroundedByLightGame()

        XCTAssertTrue(game.board.canPlaceAnyDisks(by: .dark))
        XCTAssertFalse(game.board.canPlaceAnyDisks(by: .light))
    }
}
