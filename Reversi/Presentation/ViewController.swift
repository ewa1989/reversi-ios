import UIKit

class ViewController: UIViewController {
    @IBOutlet var boardView: BoardView!
    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    
    @IBOutlet var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet var playerActivityIndicators: [UIActivityIndicatorView]!

    private var viewModel: ViewModel<ReversiGameRepositoryImpl<LocalFileSaveAndLoadStrategy>, MainQueueDispatcher>!

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = ViewModel(
            viewController: self,
            gameRepository: ReversiGameRepositoryImpl(strategy: LocalFileSaveAndLoadStrategy()),
            dispatcher: MainQueueDispatcher()
        )

        boardView.delegate = self

        viewModel.viewDidLoad(initialDiskSize: messageDiskSizeConstraint.constant)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear()
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
            messageDiskSizeConstraint.constant = viewModel.messageDiskSize
            messageDiskView.disk = side
            messageLabel.text = "'s turn"
        case .win(winner: let winner):
            messageDiskSizeConstraint.constant = viewModel.messageDiskSize
            messageDiskView.disk = winner
            messageLabel.text = " won"
        case .draw:
            messageDiskSizeConstraint.constant = 0
            messageLabel.text = "Tied"
        }
    }

    func updateGame() {
        // players
        for side in Disk.sides {
            playerControls[side.index].selectedSegmentIndex = viewModel.game.playerControls[side.index].rawValue
        }

        // board
        for x in viewModel.game.board.xRange {
            for y in viewModel.game.board.yRange {
                boardView.setDisk(viewModel.game.board.diskAt(x: x, y: y), atX: x, y: y, animated: false)
            }
        }
    }

    func showPassAlert(_ handler: ((UIAlertAction) -> Void)?) {
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
