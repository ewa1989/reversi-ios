import UIKit
import RxSwift

class ViewController: UIViewController {
    @IBOutlet var boardView: BoardView!
    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    
    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!

    private var viewModel: ViewModel<ReversiGameRepositoryImpl<LocalFileSaveAndLoadStrategy>, MainQueueDispatcher>!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = ViewModel(
            viewController: self,
            gameRepository: ReversiGameRepositoryImpl(strategy: LocalFileSaveAndLoadStrategy()),
            dispatcher: MainQueueDispatcher(),
            initialDiskSize: messageDiskSizeConstraint.constant
        )
        bind()

        boardView.delegate = self

        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear()
    }
}

// MARK: bind ViewController with ViewModel

extension ViewController {
    /// ViewControllerとViewModelをバインドします
    func bind() {
        // FIXME: 全体的にbind(to:)を使えるように変更したい。型を導入するか、.darkと.lightで変数を分ける必要があるならその方がforループ回すよりシンプルかもしれないので検討してみる。
        viewModel.computerProcessing.subscribe { [weak self] processing in
            for side in Disk.sides {
                processing[side.index]
                ? self?.playerActivityIndicators[side.index].startAnimating()
                : self?.playerActivityIndicators[side.index].stopAnimating()
            }
        }.disposed(by: disposeBag)

        viewModel.messageDiskSize.subscribe { [weak self] size in
            self?.messageDiskSizeConstraint.constant = size
        }.disposed(by: disposeBag)

        viewModel.diskCount.subscribe { [weak self] count in
            // FIXME: ViewModel#diskCountの要素数がビルド時に確定しないから（？）かsubscribeしたときに[Int]ではなくEvent<[Int]>になるので、暫定対応としてguard letを入れている。入れずに済むように修正したい。
            guard let element = count.element, element.count == Disk.sides.count else {
                return
            }
            for side in Disk.sides {
                self?.countLabels[side.index].text = "\(element[side.index])"
            }
        }.disposed(by: disposeBag)

        viewModel.message.subscribe { [weak self] (disk, label) in
            self?.messageLabel.text = label
            guard let disk = disk else {
                return
            }
            self?.messageDiskView.disk = disk
        }.disposed(by: disposeBag)

        viewModel.playerControls.subscribe { [weak self] controls in
            guard let element = controls.element, element.count == Disk.sides.count else {
                return
            }
            for side in Disk.sides {
                self?.playerControls[side.index].selectedSegmentIndex = element[side.index].rawValue
            }
        }.disposed(by: disposeBag)
    }
}

// MARK: Views

extension ViewController {
    func updateGame() {
        // board
        for x in viewModel.game.value.board.xRange {
            for y in viewModel.game.value.board.yRange {
                boardView.setDisk(viewModel.game.value.board.diskAt(x: x, y: y), atX: x, y: y, animated: false)
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
