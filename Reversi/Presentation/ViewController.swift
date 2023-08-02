import UIKit

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet var messageDiskSizeConstraint: NSLayoutConstraint!
    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `messageDiskSize` に保管された値を使います。
    var messageDiskSize: CGFloat!
    
    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!
    
    var animationCanceller: Canceller?
    var isAnimating: Bool { animationCanceller != nil }
    
    var playerCancellers: [Disk: Canceller] = [:]

    private let repository = ReversiGameRepositoryImpl(strategy: LocalFileSaveAndLoadStrategy())

    private var viewModel: ViewModel<ReversiGameRepositoryImpl<LocalFileSaveAndLoadStrategy>>!

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = ViewModel(viewController: self, gameRepository: repository)

        boardView.delegate = self

        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear()
    }
}

// MARK: Reversi logics

extension ViewController {
    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    func placeDisk(_ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) throws {
        let diskCoordinates = viewModel.game.board.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }
        
        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.animationCanceller = nil
            }
            animationCanceller = Canceller(cleanUp)
            animateSettingDisks(at: [Coordinate(x: x, y: y)] + diskCoordinates, to: disk) { [weak self] isFinished in
                guard let self = self else { return }
                guard let canceller = self.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(isFinished)
                try? self.saveGame()
                self.updateCountLabels()
            }
        } else {
            let dispatcher = self
            dispatcher.async { [weak self] in
                guard let self = self else { return }
                self.viewModel.game.board.setDisk(disk, atX: x, y: y)

                self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                for diskCoordinate in diskCoordinates {
                    self.viewModel.game.board.setDisk(disk, atX: diskCoordinate.x, y: diskCoordinate.y)

                    self.boardView.setDisk(disk, atX: diskCoordinate.x, y: diskCoordinate.y, animated: false)
                }
                completion?(true)
                try? self.saveGame()
                self.updateCountLabels()
            }
        }
    }

    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == Coordinate
    {
        guard let coordinate = coordinates.first else {
            completion(true)
            return
        }
        
        let animationCanceller = self.animationCanceller!
        viewModel.game.board.setDisk(disk, atX: coordinate.x, y: coordinate.y)

        boardView.setDisk(disk, atX: coordinate.x, y: coordinate.y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for coordinate in coordinates {
                    self.viewModel.game.board.setDisk(disk, atX: coordinate.x, y: coordinate.y)

                    self.boardView.setDisk(disk, atX: coordinate.x, y: coordinate.y, animated: false)
                }
                completion(false)
            }
        }
    }
}

// MARK: Game management

extension ViewController {
    /// ゲームの状態を初期化し、新しいゲームを開始します。
    func newGame() {
        viewModel.game = ReversiGame.newGame()

        for side in Disk.sides {
            playerControls[side.index].selectedSegmentIndex = viewModel.game.playerControls[side.index].rawValue
        }

        for y in viewModel.game.board.yRange {
            for x in viewModel.game.board.xRange {
                boardView.setDisk(viewModel.game.board.diskAt(x: x, y: y), atX: x, y: y, animated: false)
            }
        }

        updateMessageViews()
        updateCountLabels()
        
        try? saveGame()
    }
    
    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let turn = self.viewModel.game.turn else { return }
        switch viewModel.game.playerControls[turn.index] {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }

    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn() {
        guard var turn = self.viewModel.game.turn else { return }

        turn.flip()

        if !viewModel.game.board.canPlaceAnyDisks(by: turn) {
            if !viewModel.game.board.canPlaceAnyDisks(by: turn.flipped) {
                viewModel.game.turn = nil
                updateMessageViews()
            } else {
                viewModel.game.turn = turn
                updateMessageViews()

                showPassAlert() { [weak self] _ in
                    self?.nextTurn()
                }
            }
        } else {
            viewModel.game.turn = turn
            updateMessageViews()
            waitForPlayer()
        }
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer() {
        guard let turn = self.viewModel.game.turn else { preconditionFailure() }
        let coordinate = viewModel.game.board.validMoves(for: turn).randomElement()!

        playerActivityIndicators[turn.index].startAnimating()
        
        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.playerActivityIndicators[turn.index].stopAnimating()
            self.playerCancellers[turn] = nil
        }
        let canceller = Canceller(cleanUp)
        let dispatcher = self
        dispatcher.asyncAfter(seconds: 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()
            
            try! self.placeDisk(turn, atX: coordinate.x, y: coordinate.y, animated: true) { [weak self] _ in
                self?.nextTurn()
            }
        }
        
        playerCancellers[turn] = canceller
    }
}

// MARK: Views

extension ViewController {
    /// 各プレイヤーの獲得したディスクの枚数を表示します。
    func updateCountLabels() {
        for side in Disk.sides {
            countLabels[side.index].text = "\(viewModel.game.board.countDisks(of: side))"
        }
    }
    
    /// 現在の状況に応じてメッセージを表示します。
    func updateMessageViews() {
        switch viewModel.game.state {
        case .move(side: let side):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = side
            messageLabel.text = "'s turn"
        case .win(winner: let winner):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = winner
            messageLabel.text = " won"
        case .draw:
            messageDiskSizeConstraint.constant = 0
            messageLabel.text = "Tied"
        }
    }

    fileprivate func updateGame(_ game: ReversiGame) {
        self.viewModel.game = game

        // players
        for side in Disk.sides {
            playerControls[side.index].selectedSegmentIndex = game.playerControls[side.index].rawValue
        }

        // board
        for x in viewModel.game.board.xRange {
            for y in viewModel.game.board.yRange {
                boardView.setDisk(viewModel.game.board.diskAt(x: x, y: y), atX: x, y: y, animated: false)
            }
        }
    }

    fileprivate func showPassAlert(_ handler: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(
            title: "Pass",
            message: "Cannot place a disk.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: handler))
        present(alertController, animated: true)
    }

    fileprivate func showResetAlert(didOKSelect defaultHandler: ((UIAlertAction) -> Void)?, didCancelSelect cancelHandler: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: cancelHandler))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: defaultHandler))
        present(alertController, animated: true)
    }
}

protocol Dispatchable {
    func async(execute work: @escaping () -> Void)
    func asyncAfter(seconds: Double, execute work: @escaping () -> Void)
}

extension ViewController: Dispatchable {
    func async(execute work: @escaping () -> Void) {
        DispatchQueue.main.async(execute: work)
    }

    func asyncAfter(seconds: Double, execute work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }
}

// MARK: Inputs

extension ViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    /// アラートを表示して、ゲームを初期化して良いか確認し、
    /// "OK" が選択された場合ゲームを初期化します。
    @IBAction func pressResetButton(_ sender: UIButton) {
        showResetAlert(
            didOKSelect: { [weak self] _ in
                guard let self = self else { return }

                self.viewModel.reset()
            },
            didCancelSelect: { _ in }
        )
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)
        let player: Player = Player(rawValue: sender.selectedSegmentIndex)!

        viewModel.changePlayerControl(of: side, to: player)
    }
}

extension ViewController: BoardViewDelegate {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        viewModel.didSelectCellAt(x: x, y: y)
    }
}

// MARK: Save and Load

extension ViewController {
    /// ゲームの状態をファイルに書き出し、保存します。
    func saveGame() throws {
        try repository.save(viewModel.game)
    }

    /// ゲームの状態をファイルから読み込み、復元します。
    func loadGame() throws {
        let game = try repository.load()

        updateGame(game)
        updateMessageViews()
        updateCountLabels()
    }
}

// MARK: Additional types

final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?
    
    init(_ body: (() -> Void)?) {
        self.body = body
    }
    
    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}
