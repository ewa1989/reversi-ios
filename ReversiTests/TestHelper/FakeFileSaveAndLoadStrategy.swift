//
//  FakeFileSaveAndLoadStrategy.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/05.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

class FakeFileSaveAndLoadStrategy: FileSaveAndLoadStrategy {
    var fakeInput: String = ""
    func load() throws -> String {
        fakeInput
    }

    var fakeOutput: String?
    func save(_ output: String) throws {
        fakeOutput = output
    }
}
