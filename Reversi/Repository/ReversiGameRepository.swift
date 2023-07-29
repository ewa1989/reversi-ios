//
//  ReversiGameRepository.swift
//  Reversi
//
//  Created by y-uchida on 2023/07/30.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

protocol ReversiGameRepository {
    func loadGameFromFile() throws -> ReversiGame
}

enum FileIOError: Error {
    case write(path: String, cause: Error?)
    case read(path: String, cause: Error?)
}

var path: String {
    (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
}

struct ReversiGameRepositoryImpl: ReversiGameRepository {
    func loadGameFromFile() throws -> ReversiGame {
        let input = try String(contentsOfFile: path, encoding: .utf8)
        var game = ReversiGame()

        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]

        guard var line = lines.popFirst() else {
            throw FileIOError.read(path: path, cause: nil)
        }

        do { // turn
            guard
                let diskSymbol = line.popFirst(),
                let disk = Optional<Disk>(symbol: diskSymbol.description)
            else {
                throw FileIOError.read(path: path, cause: nil)
            }
            game.turn = disk
        }

        // players
        for side in Disk.sides {
            guard
                let playerSymbol = line.popFirst(),
                let playerNumber = Int(playerSymbol.description),
                let player = Player(rawValue: playerNumber)
            else {
                throw FileIOError.read(path: path, cause: nil)
            }
            game.playerControls[side.index] = player
        }

        do { // board
            guard lines.count == game.board.height else {
                throw FileIOError.read(path: path, cause: nil)
            }

            var y = 0
            while let line = lines.popFirst() {
                var x = 0
                for character in line {
                    let disk = Disk?(symbol: "\(character)").flatMap { $0 }
                    game.board.setDisk(disk, atX: x, y: y)
                    x += 1
                }
                guard x == game.board.width else {
                    throw FileIOError.read(path: path, cause: nil)
                }
                y += 1
            }
            guard y == game.board.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
        }

        return game
    }
}
