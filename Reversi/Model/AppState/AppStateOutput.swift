//
//  AppStateOutput.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation
import RxRelay

/// AppStateの状態をViewModelに伝えるためのストリームです。
class AppStateOutput {
    let game: PublishRelay<ReversiGame>
    let computerProcessing: PublishRelay<[Bool]>
    let passAlert: PublishRelay<PassAlert>
    let diskToPlace: PublishRelay<DiskPlacement>
    let finishComputerProcessing: PublishRelay<Coordinate>

    init(
        game: PublishRelay<ReversiGame>,
        computerProcessing: PublishRelay<[Bool]>,
        passAlert: PublishRelay<PassAlert>,
        diskToPlace: PublishRelay<DiskPlacement>,
        finishComputerProcessing: PublishRelay<Coordinate>
    ) {
        self.game = game
        self.computerProcessing = computerProcessing
        self.passAlert = passAlert
        self.diskToPlace = diskToPlace
        self.finishComputerProcessing = finishComputerProcessing
    }
}
