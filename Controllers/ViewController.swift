//
//  ViewController.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 04.05.16.
//

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

    fileprivate var volumeHandler: TTMVolumeButtonHandler?
    
    fileprivate let gameCellId = "GameCell"
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return TTMMatch.currentMatch.matchFinished ? .darkContent : .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.volumeHandler = TTMVolumeButtonHandler(up: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.simulateButtonTap(for: TTMMatch.currentMatch.players[1])
        }, downBlock: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.simulateButtonTap(for: TTMMatch.currentMatch.players[0])
        })
        self.volumeHandler?.start(true)
        
        self.buttonsContainer.layer.cornerRadius = 36.0
        
        let longTapRecognizer1 = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.button1LongTapped(_:)))
        self.leftButton.addGestureRecognizer(longTapRecognizer1)
        self.leftButton.undoPosition = .left
        self.leftButton.undoButton.addTarget(self, action: #selector(ViewController.player1UndoTapped(_:)), for: .touchUpInside)
        
        let longTapRecognizer2 = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.button2LongTapped(_:)))
        self.rightButton.addGestureRecognizer(longTapRecognizer2)
        self.rightButton.undoPosition = .right
        self.rightButton.undoButton.addTarget(self, action: #selector(ViewController.player2UndoTapped(_:)), for: .touchUpInside)
        
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
        
        if IS_SMALL_SCREEN {
            self.verticalMarginConstraint.constant = 0.0
            self.tableViewTopMarginConstraint.constant = 0.0
            self.settingsButtonBottomMarginConstraint.constant = 0.0
        } else {
            self.verticalMarginConstraint.constant = 16.0
            self.tableViewTopMarginConstraint.constant = 8.0
            self.settingsButtonBottomMarginConstraint.constant = 16.0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateFromCurrentGame(false, playerAction: nil)
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if (motion == .motionShake) {
            if TTMMatch.currentMatch.serve == nil {
                self.showGameSettingsDialog()
            } else {
                self.showRestartMatchDialog()
            }
        }
    }
    
    fileprivate func showRestartMatchDialog(_ sender: UIView? = nil) {
        let dialog = UIAlertController(title: L("Shake_ActionSheet_Title"), message: nil, preferredStyle: .actionSheet)
        let resetGameAction = UIAlertAction(title: L("Shake_ActionSheet_Confirm"), style: .destructive, handler: {[weak self] (action) in
            TTMAnalytics.matchReset()
            TTMMatch.currentMatch.reset()
            self?.updateFromCurrentGame(false, playerAction: nil)
        })
        dialog.addAction(resetGameAction)
        let cancelResetGameAction = UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil)
        dialog.addAction(cancelResetGameAction)
        if let popover = dialog.popoverPresentationController {
            popover.permittedArrowDirections = .down
            popover.sourceView = self.view
            let view: UIView = sender ?? self.settingsButton
            popover.sourceRect = self.view.convert(view.frame, from: view.superview)
        }
        self.present(dialog, animated: true, completion: nil)
    }
    
    fileprivate func showGameSettingsDialog(_ sender: UIView? = nil) {
        let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let threeGameAction = UIAlertAction(title: L("MatchSettings_3games"), style: .default, handler: {[weak self] (action) in
            var settings = TTMMatch.currentMatch.settings
            settings.gameCount = 3
            TTMMatch.currentMatch.settings = settings
            TTMAnalytics.settingsChanged(gameCount: 3)
            self?.updateFromCurrentGame(false, playerAction: nil)
        })
        dialog.addAction(threeGameAction)
        let fiveGameAction = UIAlertAction(title: L("MatchSettings_5games"), style: .default, handler: {[weak self] (action) in
            var settings = TTMMatch.currentMatch.settings
            settings.gameCount = 5
            TTMMatch.currentMatch.settings = settings
            TTMAnalytics.settingsChanged(gameCount: 5)
            self?.updateFromCurrentGame(false, playerAction: nil)
        })
        dialog.addAction(fiveGameAction)
        let sevenGameAction = UIAlertAction(title: L("MatchSettings_7games"), style: .default, handler: {[weak self] (action) in
            var settings = TTMMatch.currentMatch.settings
            settings.gameCount = 7
            TTMMatch.currentMatch.settings = settings
            TTMAnalytics.settingsChanged(gameCount: 7)
            self?.updateFromCurrentGame(false, playerAction: nil)
        })
        dialog.addAction(sevenGameAction)
        
        let cancelAction = UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil)
        dialog.addAction(cancelAction)
        
        if let popover = dialog.popoverPresentationController {
            popover.permittedArrowDirections = .down
            popover.sourceView = self.view
            let view: UIView = sender ?? self.settingsButton
            popover.sourceRect = self.view.convert(view.frame, from: view.superview)
        }
        self.present(dialog, animated: true, completion: nil)
    }

    func updateFromCurrentGame(_ animated: Bool, playerAction: TTMMatchPlayer?, handleRandomServe: Bool = true) {
        self.gamesTableView.reloadData()
        
        let match = TTMMatch.currentMatch
        
        let leftPlayer = match.players[0]
        let rightPlayer = match.players[1]
        self.leftButton.update(match, player: leftPlayer, animated: animated && leftPlayer == playerAction)
        self.rightButton.update(match, player: rightPlayer, animated: animated && rightPlayer == playerAction)
        
        if match.matchFinished {
            UIApplication.shared.isIdleTimerDisabled = false
            self.matchFinished(match.winner)
            self.settingsButton.isHidden = true
        } else if match.gameFinished {
            self.gameFinished(match.gameWinner)
            self.settingsButton.isHidden = false
            self.settingsButton.setImage(UIImage(named: "settings")?.tinted(with: UIColor.white.withAlphaComponent(0.5)), for: .normal)
            self.settingsButton.backgroundColor = nil
        } else {
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.backgroundColor = UIColor.white
            self.buttonsContainer.backgroundColor = UIColor.clear
            UIApplication.shared.isIdleTimerDisabled = true
            self.settingsButton.isHidden = false
            self.settingsButton.setImage(UIImage(named: "settings")?.tinted(with: UIColor.ttmGrayColor), for: .normal)
            self.settingsButton.backgroundColor = UIColor.ttmGrayColor.withAlphaComponent(0.2)
        }
        
        if match.serve == nil {
            if handleRandomServe {
                self.randomServeButtonBackground.isHidden = false
                self.randomServeButton.isHidden = false
            }
            self.gamesTableView.isHidden = true
            self.settingsButton.setImage(nil, for: .normal)
            self.settingsButton.setTitle("\(match.settings.gameCount)", for: .normal)
        } else {
            if handleRandomServe {
                self.randomServeButtonBackground.isHidden = true
                self.randomServeButton.isHidden = true
            }
            self.gamesTableView.isHidden = false
            self.settingsButton.setTitle(nil, for: .normal)
        }
    }
    
    @IBAction func randomizeServe(_ sender: UIButton) {
        guard TTMMatch.currentMatch.firstServe == nil else { return }
        
        TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.tap)
        
        self.animateRandomizationServe {[weak self] in
            TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.tapServiceChanged)
            let player = TTMMatchPlayer.rand()
            TTMMatch.currentMatch.firstServe = player
            TTMAnalytics.matchStarted(gameCount: TTMMatch.currentMatch.settings.gameCount)
            self?.updateFromCurrentGame(false, playerAction: player, handleRandomServe: false)
        }
    }
    
    @IBAction func showSettings(_ sender: UIButton) {
        if TTMMatch.currentMatch.serve == nil {
            self.showGameSettingsDialog(sender)
        } else {
            self.showRestartMatchDialog(sender)
        }
    }
    
    @IBAction func player1ScoreTapped(_ sender: TTMSelectableButton) {
        self.processTap(TTMMatch.currentMatch.players[0])
    }
    
    @IBAction func player2ScoreTapped(_ sender: TTMSelectableButton) {
        self.processTap(TTMMatch.currentMatch.players[1])
    }
    
    @objc func player1UndoTapped(_ sender: UIButton) {
        self.cancelLastAction()
    }

    @objc func player2UndoTapped(_ sender: UIButton) {
        self.cancelLastAction()
    }
    
    fileprivate func processTap(_ player: TTMMatchPlayer) {
        let match = TTMMatch.currentMatch
        
        let hasServe = match.serve != nil
        let gameFinished = match.gameFinished
        let matchFinished = match.matchFinished
        let isMatchStart = !matchFinished && !hasServe

        if matchFinished {
            TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.newGame)
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.backgroundColor = UIColor.white
            match.reset()
        } else {
            if gameFinished {
                self.buttonsContainer.backgroundColor = UIColor.clear
            }
            if isMatchStart {
                TTMAnalytics.matchStarted(gameCount: match.settings.gameCount)
            }
            match.playerAction(player)
        }
        
        let gameFinishedAfter = match.gameFinished
        let matchFinishedAfter = match.matchFinished

        if !matchFinished && matchFinishedAfter {
            TTMAnalytics.matchCompleted(gamesPlayed: match.gameScores.count)
        } else if !gameFinished && gameFinishedAfter {
            TTMAnalytics.gameCompleted(gameNumber: match.gameScores.count)
        }

        self.updateFromCurrentGame(hasServe && !gameFinished && !matchFinished && !gameFinishedAfter && !matchFinishedAfter, playerAction: player)
        self.disableActions()
    }
    
    fileprivate func simulateButtonTap(for player: TTMMatchPlayer) {
        guard self.view.isUserInteractionEnabled else { return }
        self.processTap(player)
    }
    
    fileprivate func disableActions() {
        self.view.isUserInteractionEnabled = false
        delay(secondsToDeclineTaps, closure: {[weak self] ()->() in
            self?.view.isUserInteractionEnabled = true
            })
    }
    
    @objc func button1LongTapped(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == .began) {
            self.cancelLastAction()
        }
    }

    @objc func button2LongTapped(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == .began) {
            self.cancelLastAction()
        }
    }

    @objc func backgroundTapped(_ sender: UITapGestureRecognizer) {
        if TTMMatch.currentMatch.gameFinished || TTMMatch.currentMatch.matchFinished {
            self.processTap(TTMMatch.currentMatch.players[0])
        }
    }

    @objc func cancelLastAction() {
        if TTMMatch.currentMatch.firstServe != nil {
            TTMAnalytics.undoUsed()
        }
        TTMMatch.currentMatch.undo()
        if !TTMMatch.currentMatch.matchFinished {
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.backgroundColor = UIColor.white
        }
        if !TTMMatch.currentMatch.gameFinished {
            self.buttonsContainer.backgroundColor = UIColor.clear
        }
        self.updateFromCurrentGame(false, playerAction: nil)
        self.disableActions()
    }
    
    func matchFinished(_ winner: TTMMatchPlayer?) {
        if let winner = winner {
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.backgroundColor = winner.color()
        }
    }
    
    func gameFinished(_ winner: TTMMatchPlayer?) {
        if let winner = winner {
            self.buttonsContainer.backgroundColor = winner.color()
        }
    }
}

extension ViewController: UITableViewDelegate {
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TTMMatch.currentMatch.settings.gameCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: gameCellId, for: indexPath) as! TTMGameCell
        cell.update(TTMMatch.currentMatch, gameIndex: indexPath.row, players: TTMMatch.currentMatch.players)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 32.0
    }
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.simulateButtonTap(for: TTMMatch.currentMatch.players[0])
        return true
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
