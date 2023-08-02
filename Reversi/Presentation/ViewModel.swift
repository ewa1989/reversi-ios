//
//  ViewModel.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/01.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

class ViewModel<GameRepository: ReversiGameRepository, Dispatcher: Dispatchable> {
    /// リファクタリング最中の暫定措置として参照を持っているだけなので後で消す予定
    private weak var viewController: ViewController!
    private let gameRepository: GameRepository
    private let dispatcher: Dispatcher

    /// ゲームの状態を管理します
    var game = ReversiGame()

    var viewHasAppeared: Bool = false

    init(
        viewController: ViewController!,
        gameRepository: GameRepository,
        dispatcher: Dispatcher
    ) {
        self.viewController = viewController
        self.gameRepository = gameRepository
        self.dispatcher = dispatcher
    }

    func viewDidLoad() {
        viewController.messageDiskSize = viewController.messageDiskSizeConstraint.constant

        do {
            try loadGame()
        } catch _ {
            newGame()
        }
    }

    func viewDidAppear() {
        if viewHasAppeared { return }
        viewHasAppeared = true
        waitForPlayer()
    }

    func reset() {
        viewController.animationCanceller?.cancel()
        viewController.animationCanceller = nil

        for side in Disk.sides {
            viewController.playerCancellers[side]?.cancel()
            viewController.playerCancellers.removeValue(forKey: side)
        }

        newGame()
        waitForPlayer()
    }

    func changePlayerControl(of side: Disk, to player: Player) {
        game.playerControls[side.index] = player

        try? viewController.saveGame()

        if let canceller = viewController.playerCancellers[side] {
            canceller.cancel()
        }

        if !viewController.isAnimating, side == game.turn, case .computer = player {
            playTurnOfComputer()
        }
    }

    func didSelectCellAt(x: Int, y: Int) {
        guard let turn = game.turn else { return }
        if viewController.isAnimating { return }
        guard case .manual = game.playerControls[turn.index] else { return }
        // try? because doing nothing when an error occurs
        try? viewController.placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }

    /// ゲームの状態をファイルから読み込み、復元します。
    private func loadGame() throws {
        let game = try gameRepository.load()

        viewController.updateGame(game)
        viewController.updateMessageViews()
        viewController.updateCountLabels()
    }

    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let turn = self.game.turn else { return }
        switch game.playerControls[turn.index] {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }

    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    private func playTurnOfComputer() {
        guard let turn = self.game.turn else { preconditionFailure() }
        let coordinate = game.board.validMoves(for: turn).randomElement()!

        viewController.playerActivityIndicators[turn.index].startAnimating()

        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.viewController.playerActivityIndicators[turn.index].stopAnimating()
            self.viewController.playerCancellers[turn] = nil
        }
        let canceller = Canceller(cleanUp)
        dispatcher.asyncAfter(seconds: 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()

            try! self.viewController.placeDisk(turn, atX: coordinate.x, y: coordinate.y, animated: true) { [weak self] _ in
                self?.nextTurn()
            }
        }

        viewController.playerCancellers[turn] = canceller
    }

    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    private func nextTurn() {
        guard var turn = self.game.turn else { return }

        turn.flip()

        if !game.board.canPlaceAnyDisks(by: turn) {
            if !game.board.canPlaceAnyDisks(by: turn.flipped) {
                game.turn = nil
                viewController.updateMessageViews()
            } else {
                game.turn = turn
                viewController.updateMessageViews()

                viewController.showPassAlert() { [weak self] _ in
                    self?.nextTurn()
                }
            }
        } else {
            game.turn = turn
            viewController.updateMessageViews()
            waitForPlayer()
        }
    }

    /// ゲームの状態を初期化し、新しいゲームを開始します。
    private func newGame() {
        game = ReversiGame.newGame()

        for side in Disk.sides {
            viewController.playerControls[side.index].selectedSegmentIndex = game.playerControls[side.index].rawValue
        }

        for y in game.board.yRange {
            for x in game.board.xRange {
                viewController.boardView.setDisk(game.board.diskAt(x: x, y: y), atX: x, y: y, animated: false)
            }
        }

        viewController.updateMessageViews()
        viewController.updateCountLabels()

        try? viewController.saveGame()
    }
}
