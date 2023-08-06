//
//  TestDoubleDispatchers.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/05.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

class SynchronousDispatcher: Dispatchable {
    func async(execute work: @escaping () -> Void) {
        work()
    }

    func asyncAfter(seconds: Double, execute work: @escaping () -> Void) {
        work()
    }
}

class TimingControllableDispatcher: Dispatchable {
    var work: (() -> Void)?

    func async(execute work: @escaping () -> Void) {
        self.work = work
    }

    func asyncAfter(seconds: Double, execute work: @escaping () -> Void) {
        self.work = work
    }
}
