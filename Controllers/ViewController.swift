//
//  ViewController.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 04.05.16.
//

import Observation
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var leftButton: TTMSelectableButton!
    @IBOutlet weak var rightButton: TTMSelectableButton!
    @IBOutlet weak var buttonsContainer: UIView!
    @IBOutlet weak var gamesTableView: UITableView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var randomServeButton: UIButton!
    @IBOutlet weak var randomServeButtonBackground: UIView!

    @IBOutlet weak var verticalMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsButtonBottomMarginConstraint: NSLayoutConstraint!

    fileprivate let viewModel = MatchViewModel()
    fileprivate var volumeHandler: TTMVolumeButtonHandler?
    
    fileprivate let gameCellId = "GameCell"
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return self.viewModel.matchWinner != nil ? .darkContent : .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.volumeHandler = TTMVolumeButtonHandler(up: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.tap(strongSelf.viewModel.rightPlayer)
        }, downBlock: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.tap(strongSelf.viewModel.leftPlayer)
        })
        self.volumeHandler?.start(true)
        
        self.buttonsContainer.layer.cornerRadius = 36.0
        
        let longTapRecognizer1 = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.buttonLongTapped(_:)))
        self.leftButton.addGestureRecognizer(longTapRecognizer1)
        self.leftButton.undoPosition = .left
        self.leftButton.undoButton.addTarget(self, action: #selector(ViewController.undoTapped(_:)), for: .touchUpInside)
        
        let longTapRecognizer2 = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.buttonLongTapped(_:)))
        self.rightButton.addGestureRecognizer(longTapRecognizer2)
        self.rightButton.undoPosition = .right
        self.rightButton.undoButton.addTarget(self, action: #selector(ViewController.undoTapped(_:)), for: .touchUpInside)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.backgroundTapped(_:)))
        self.view.addGestureRecognizer(tapRecognizer)
        
        self.gamesTableView.backgroundColor = UIColor.clear
        self.gamesTableView.isScrollEnabled = false
        self.gamesTableView.separatorColor = UIColor.clear
        self.gamesTableView.register(UINib(nibName: "TTMGameCell", bundle: nil), forCellReuseIdentifier: gameCellId)
        
        self.settingsButton.layer.cornerRadius = 24.0
        self.settingsButton.titleLabel?.font = UIFont.ttmFontBlackOfSize(18.0)
        self.settingsButton.setTitleColor(UIColor.ttmGrayColor, for: .normal)
        
        self.randomServeButton.setImage(UIImage(named: "swap_arrows")?.tinted(with: UIColor.ttmGrayColor), for: .normal)
        self.randomServeButton.backgroundColor = UIColor.ttmGrayColor.opaqueColor(0.2)
        self.randomServeButton.layer.cornerRadius = 64.0
        
        self.randomServeButtonBackground.layer.cornerRadius = 70.0
        
        self.leftButton.accessibilityIdentifier = "score.left"
        self.rightButton.accessibilityIdentifier = "score.right"
        self.leftButton.undoButton.accessibilityIdentifier = "undo.left"
        self.rightButton.undoButton.accessibilityIdentifier = "undo.right"
        self.settingsButton.accessibilityIdentifier = "settings"
        self.randomServeButton.accessibilityIdentifier = "randomServe"
        
        if IS_SMALL_SCREEN {
            self.verticalMarginConstraint.constant = 0.0
            self.tableViewTopMarginConstraint.constant = 0.0
            self.settingsButtonBottomMarginConstraint.constant = 0.0
        } else {
            self.verticalMarginConstraint.constant = 16.0
            self.tableViewTopMarginConstraint.constant = 8.0
            self.settingsButtonBottomMarginConstraint.constant = 16.0
        }
        
        self.observeInputLock()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateUI()
    }

    fileprivate func showRestartMatchDialog(_ sender: UIView? = nil) {
        let dialog = UIAlertController(title: L("Shake_ActionSheet_Title"), message: nil, preferredStyle: .actionSheet)
        let resetGameAction = UIAlertAction(title: L("Shake_ActionSheet_Confirm"), style: .destructive, handler: {[weak self] (action) in
            self?.viewModel.resetMatch()
            self?.updateUI()
        })
        dialog.addAction(resetGameAction)
        let cancelResetGameAction = UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil)
        dialog.addAction(cancelResetGameAction)
        self.presentActionSheet(dialog, from: sender)
    }
    
    fileprivate func showGameSettingsDialog(_ sender: UIView? = nil) {
        let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let options = [(3, "MatchSettings_3games"), (5, "MatchSettings_5games"), (7, "MatchSettings_7games")]
        for (gameCount, titleKey) in options {
            let action = UIAlertAction(title: L(titleKey), style: .default, handler: {[weak self] (action) in
                self?.viewModel.setGameCount(gameCount)
                self?.updateUI()
            })
            dialog.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil)
        dialog.addAction(cancelAction)
        self.presentActionSheet(dialog, from: sender)
    }
    
    fileprivate func presentActionSheet(_ dialog: UIAlertController, from sender: UIView?) {
        if let popover = dialog.popoverPresentationController {
            popover.permittedArrowDirections = .down
            popover.sourceView = self.view
            let view: UIView = sender ?? self.settingsButton
            popover.sourceRect = self.view.convert(view.frame, from: view.superview)
        }
        self.present(dialog, animated: true, completion: nil)
    }

    /// Renders the view model's state. `animatedPlayer` gets the point animation on their button.
    func updateUI(animatedPlayer: TTMMatchPlayer? = nil, handleRandomServe: Bool = true) {
        let viewModel = self.viewModel
        let match = viewModel.match
        
        self.gamesTableView.reloadData()
        
        let leftPlayer = viewModel.leftPlayer
        let rightPlayer = viewModel.rightPlayer
        self.leftButton.update(match, player: leftPlayer, animated: leftPlayer == animatedPlayer)
        self.rightButton.update(match, player: rightPlayer, animated: rightPlayer == animatedPlayer)
        
        self.setNeedsStatusBarAppearanceUpdate()
        self.view.backgroundColor = viewModel.matchWinner?.color() ?? UIColor.white
        self.buttonsContainer.backgroundColor = viewModel.gameWinner?.color() ?? UIColor.clear
        UIApplication.shared.isIdleTimerDisabled = viewModel.isIdleTimerDisabled
        
        switch viewModel.settingsMode {
        case .hidden:
            self.settingsButton.isHidden = true
        case .gameCount(let gameCount):
            self.settingsButton.isHidden = false
            self.settingsButton.setImage(nil, for: .normal)
            self.settingsButton.setTitle("\(gameCount)", for: .normal)
            self.settingsButton.backgroundColor = UIColor.ttmGrayColor.withAlphaComponent(0.2)
        case .reset:
            self.settingsButton.isHidden = false
            self.settingsButton.setTitle(nil, for: .normal)
            if viewModel.gameWinner != nil {
                self.settingsButton.setImage(UIImage(named: "settings")?.tinted(with: UIColor.white.withAlphaComponent(0.5)), for: .normal)
                self.settingsButton.backgroundColor = nil
            } else {
                self.settingsButton.setImage(UIImage(named: "settings")?.tinted(with: UIColor.ttmGrayColor), for: .normal)
                self.settingsButton.backgroundColor = UIColor.ttmGrayColor.withAlphaComponent(0.2)
            }
        }
        
        if handleRandomServe {
            self.randomServeButtonBackground.isHidden = !viewModel.showsServeRandomizer
            self.randomServeButton.isHidden = !viewModel.showsServeRandomizer
        }
        self.gamesTableView.isHidden = !viewModel.showsGames
    }
    
    /// Mirrors the view model's input lock onto the view, so touches are ignored while it is locked.
    fileprivate func observeInputLock() {
        withObservationTracking {
            self.view.isUserInteractionEnabled = !self.viewModel.isInputLocked
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.observeInputLock()
            }
        }
    }
    
    @IBAction func randomizeServe(_ sender: UIButton) {
        guard self.viewModel.canRandomizeServe else { return }
        
        self.viewModel.beginServeRandomization()
        
        self.animateRandomizationServe {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.viewModel.completeServeRandomization()
            strongSelf.updateUI(handleRandomServe: false)
        }
    }
    
    @IBAction func showSettings(_ sender: UIButton) {
        switch self.viewModel.settingsMode {
        case .gameCount:
            self.showGameSettingsDialog(sender)
        case .reset:
            self.showRestartMatchDialog(sender)
        case .hidden:
            break
        }
    }
    
    @IBAction func player1ScoreTapped(_ sender: TTMSelectableButton) {
        self.tap(self.viewModel.leftPlayer)
    }
    
    @IBAction func player2ScoreTapped(_ sender: TTMSelectableButton) {
        self.tap(self.viewModel.rightPlayer)
    }
    
    @objc func undoTapped(_ sender: UIButton) {
        self.undo()
    }
    
    fileprivate func tap(_ player: TTMMatchPlayer) {
        let animated = self.viewModel.tap(player)
        self.updateUI(animatedPlayer: animated ? player : nil)
    }
    
    @objc func buttonLongTapped(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == .began) {
            self.undo()
        }
    }

    @objc func backgroundTapped(_ sender: UITapGestureRecognizer) {
        self.viewModel.backgroundTap()
        self.updateUI()
    }

    fileprivate func undo() {
        self.viewModel.undo()
        self.updateUI()
    }
}

extension ViewController: UITableViewDelegate {
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.match.settings.gameCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: gameCellId, for: indexPath) as! TTMGameCell
        cell.update(self.viewModel.match, gameIndex: indexPath.row, players: self.viewModel.match.players)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 32.0
    }
}

extension ViewController {
    fileprivate func animateRandomizationServe(_ completion: @escaping ()->()) {
        UIView.animate(withDuration: 1.5, animations: {[weak self] in
            self?.randomServeButton.transform = CGAffineTransform(scaleX: 2.0, y: 2.0).concatenating(CGAffineTransform(rotationAngle: CGFloat.pi))
        }) {[weak self] (completed) in
            self?.randomServeButtonBackground.isHidden = true
            delay(0.25, closure: {
                completion()
            })
            UIView.animate(withDuration: 0.5, animations: {[weak self] in
                self?.randomServeButton.alpha = 0.0
                self?.randomServeButton.transform = CGAffineTransform(scaleX: 10.0, y: 10.0).concatenating(CGAffineTransform(rotationAngle: CGFloat.pi))
            }, completion: {[weak self] (completed) in
                self?.randomServeButton.transform = CGAffineTransform.identity
                self?.randomServeButton.alpha = 1.0
                self?.randomServeButton.isHidden = true
            })
        }
    }
}
