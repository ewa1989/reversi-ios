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
    /// 状態としての処理を実行します。
    func start(viewHasAppeared: Bool)

    /// ユーザー入力が行われた時に状態を変更します。
    /// - Parameter coordinate: ユーザー入力されたセルの位置です。
    /// - Returns: 行動後の状態です
    func inputByUser(coordinate: Coordinate) throws -> AppState

    /// コンピューター入力が行われた時に状態を変更します。
    /// - Parameter coordinate: ユーザー入力されたセルの位置です。
    /// - Returns: 行動後の状態です
    func inputByComputer(coordinate: Coordinate) throws -> AppState

    /// パスを了承した時に状態を変更します。
    /// - Returns: 行動後の状態です。
    func acceptPass() throws -> AppState

    /// プレイヤーモードを変更した時に状態を変更します。
    /// - Parameters:
    ///   - side: プレイヤーモードを変更するプレイヤーです。
    ///   - player: プレイヤーモードを変更する先です。
    /// - Returns: 行動後の状態です。
    func changePlayerControl(of side: Disk, to player: Player) throws -> AppState

    /// リセットした時に状態を変更します。
    /// - Returns: 行動後の状態です。
    func reset() throws -> AppState

    /// セル1つの描画完了した時に状態を変更します。
    /// - Returns: 行動後の状態です。
    func finishUpdatingOneCell(isFinished: Bool) throws -> AppState
}

/// 各アプリの状態で無効な行動が選択された時に投げるエラーです。
struct InvalidActionError: Error {}
