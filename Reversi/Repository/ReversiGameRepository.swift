//
//  ReversiGameRepository.swift
//  Reversi
//
//  Created by y-uchida on 2023/07/30.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

protocol ReversiGameRepository {
    func load() throws -> ReversiGame
}

private enum FileIOError: Error {
    case write(path: String, cause: Error?)
    case read(path: String, cause: Error?)
}

private var path: String {
    (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
}

struct ReversiGameRepositoryImpl<Strategy: FileSaveAndLoadStrategy>: ReversiGameRepository {
    private let strategy: Strategy

    init(strategy: Strategy) {
        self.strategy = strategy
    }

    func load() throws -> ReversiGame {
        let input = try strategy.load()
        return try makeGameParsing(input)
    }

    private func makeGameParsing(_ input: String) throws -> ReversiGame {
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

protocol ReversiGameRepositoryTemp {
    func saveGameToFile(_ game: ReversiGame) throws
}

extension ReversiGameRepositoryImpl: ReversiGameRepositoryTemp {
    func saveGameToFile(_ game: ReversiGame) throws {
        var output: String = ""

        output += game.turn.symbol

        for side in Disk.sides {
            output += game.playerControls[side.index].rawValue.description
        }
        output += "\n"

        for y in game.board.yRange {
            for x in game.board.xRange {
                output += game.board.diskAt(x: x, y: y).symbol
            }
            output += "\n"
        }

        do {
            try output.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }
}

protocol FileSaveAndLoadStrategy {
    func load() throws -> String
}

struct LocalFileSaveAndLoadStrategy: FileSaveAndLoadStrategy {
    func load() throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }
}
