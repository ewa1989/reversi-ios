//
//  ViewModel.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/01.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

class ViewModel<GameRepository: ReversiGameRepository> {
    /// リファクタリング最中の暫定措置として参照を持っているだけなので後で消す予定
    private weak var viewController: ViewController!
    private let gameRepository: GameRepository

    /// ゲームの状態を管理します
    var game = ReversiGame()

    var viewHasAppeared: Bool = false

    init(viewController: ViewController!, gameRepository: GameRepository) {
        self.viewController = viewController
        self.gameRepository = gameRepository
    }

    func viewDidLoad() {
        viewController.messageDiskSize = viewController.messageDiskSizeConstraint.constant

        do {
            try viewController.loadGame()
        } catch _ {
            viewController.newGame()
        }
    }

    func viewDidAppear() {
        if viewHasAppeared { return }
        viewHasAppeared = true
        viewController.waitForPlayer()
    }

    func reset() {
        viewController.animationCanceller?.cancel()
        viewController.animationCanceller = nil

        for side in Disk.sides {
            viewController.playerCancellers[side]?.cancel()
            viewController.playerCancellers.removeValue(forKey: side)
        }

        viewController.newGame()
        viewController.waitForPlayer()
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
}
