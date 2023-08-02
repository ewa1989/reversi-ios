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
            viewController.newGame()
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

        viewController.newGame()
        waitForPlayer()
    }

    func changePlayerControl(of side: Disk, to player: Player) {
        game.playerControls[side.index] = player

        try? viewController.saveGame()

        if let canceller = viewController.playerCancellers[side] {
            canceller.cancel()
        }

        if !viewController.isAnimating, side == game.turn, case .computer = player {
            viewController.playTurnOfComputer()
        }
    }

    func didSelectCellAt(x: Int, y: Int) {
        guard let turn = game.turn else { return }
        if viewController.isAnimating { return }
        guard case .manual = game.playerControls[turn.index] else { return }
        // try? because doing nothing when an error occurs
        try? viewController.placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
            self?.viewController.nextTurn()
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
            viewController.playTurnOfComputer()
        }
    }
}
