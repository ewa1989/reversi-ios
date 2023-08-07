//
//  TestableObserverFactory.swift
//  ReversiTests
//
//  Created by y-uchida on 2023/08/06.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation
import RxSwift
import RxTest
import RxCocoa

extension Observable {
    func makeTestableObserver(testScheduler: TestScheduler, disposeBag: DisposeBag) -> TestableObserver<Element> {
        let testable = testScheduler.createObserver(Element.self)
        self.bind(to: testable).disposed(by: disposeBag)
        return testable
    }
}
