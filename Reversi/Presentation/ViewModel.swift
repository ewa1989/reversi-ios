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

    init(viewController: ViewController!, gameRepository: GameRepository) {
        self.viewController = viewController
        self.gameRepository = gameRepository
    }
}
