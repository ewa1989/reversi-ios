//
//  AppState.swift
//  Reversi
//
//  Created by y-uchida on 2023/08/08.
//  Copyright © 2023 Yuta Koshizawa. All rights reserved.
//

import Foundation

/// 次の5つのアプリの状態を示します。画面描画中のみ動的で、アプリの実行中にのみ現れる状態です。
/// - ユーザー入力待ち
/// - コンピューター入力待ち
/// - パス了承待ち
/// - 画面描画中
/// - ゲーム終了
protocol AppState {
    var game: ReversiGame { get }

    /// ユーザー入力が行われた時に状態を変更します。
    /// - Parameter coordinate: ユーザー入力されたセルの位置です。
    /// - Returns: 行動後の状態です
    func inputByUser(coordinate: Coordinate) throws -> AppState

    /// コンピューター入力が行われた時に状態を変更します。
    /// - Parameter coordinate: ユーザー入力されたセルの位置です。
    /// - Returns: 行動後の状態です
    func inputByComputer(coordinate: Coordinate) throws -> AppState
}

/// 各アプリの状態で無効な行動が選択された時に投げるエラーです。
struct InvalidActionError: Error {}
