//
//  Dispatchable.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/02.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

protocol Dispatchable {
    func async(execute work: @escaping () -> Void)
    func asyncAfter(seconds: Double, execute work: @escaping () -> Void)
}

struct MainQueueDispatcher: Dispatchable {
    func async(execute work: @escaping () -> Void) {
        DispatchQueue.main.async(execute: work)
    }

    func asyncAfter(seconds: Double, execute work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }
}
