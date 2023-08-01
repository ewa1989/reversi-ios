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
}
