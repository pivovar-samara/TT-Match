//
//  TTMSelectableButton.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 04.05.16.
//

import UIKit

enum TTMSelectableButtonUndoButtonPosition {
    case left, right
}

class TTMSelectableButton: UIButton {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var gamesLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    weak var undoButton: UIButton!
    var undoButtonLeftConstraint: NSLayoutConstraint!
    
    var undoPosition: TTMSelectableButtonUndoButtonPosition = .left {
        didSet {
            switch self.undoPosition {
            case .left:
                self.undoButtonLeftConstraint.isActive = true
                self.undoDefaultImage = UIImage(named: "undo_left")
            case .right:
                self.undoButtonLeftConstraint.isActive = false
                self.undoDefaultImage = UIImage(named: "undo_right")
            }
        }
    }
    fileprivate var undoDefaultImage: UIImage? = UIImage(named: "undo_left")
    
    fileprivate var match: TTMMatch?
    fileprivate var player: TTMMatchPlayer?
    
    var borderColor:UIColor?
    
    var defaultColor:UIColor?
    
    fileprivate var currentColor:UIColor? {
        didSet {
            if let color = self.currentColor {
                self.backgroundView.backgroundColor = color
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let view = Bundle.main.loadNibNamed("TTMSelectableButton", owner: self, options: nil)?[0] as! UIView
        self.addSubview(view)
        view.frame = self.bounds
        view.backgroundColor = UIColor.clear
        view.isUserInteractionEnabled = false
        
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(button)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: button, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -16.0),
            NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 48.0),
            NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 48.0)
            ])
        
        self.undoButtonLeftConstraint = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 16.0)
        self.addConstraint(self.undoButtonLeftConstraint)
        
        let rightConstraint = NSLayoutConstraint(item: button, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16.0)
        rightConstraint.priority = UILayoutPriority.defaultHigh
        self.addConstraint(rightConstraint)
        
        self.undoButton = button
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.clear
        
        self.addTarget(self, action: #selector(TTMSelectableButton.touchDown(_:)), for: .touchDown)
        self.addTarget(self, action: #selector(TTMSelectableButton.touchUpInside(_:)), for: .touchUpInside)
        self.addTarget(self, action: #selector(TTMSelectableButton.touchUpOutsideOrCancelled(_:)), for: [.touchUpOutside, .touchCancel, .touchDragOutside])
        
        self.backgroundView.layer.cornerRadius = 36.0
        self.backgroundView.layer.masksToBounds = true
        
        self.backgroundView.layer.borderWidth = 4.0
        
        self.gamesLabel.font = UIFont.ttmFontHeavyOfSize(36.0)
        
        self.undoButton?.layer.cornerRadius = 24.0
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.backgroundView.backgroundColor = (self.isHighlighted ? self.defaultColor : self.currentColor) ?? UIColor.clear
            self.updateColors()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let font = TTMSelectableButton.fontToFitWidth(self.bounds.size.width - 32.0)
        self.label.font = font
    }
    
    static func fontToFitWidth(_ width: CGFloat) -> UIFont {
        
        // http://stackoverflow.com/questions/31768036/how-to-adjust-a-uilabel-font-size-based-on-the-height-available-to-the-label
        
        var minFontSize: CGFloat = 100.0
        var maxFontSize: CGFloat = IS_IPAD ? 384.0 : 192.0
        var fontSizeAverage: CGFloat = 0.0
        var textAndLabelHeightDiff: CGFloat = 0.0
        
        while (minFontSize <= maxFontSize) {
            fontSizeAverage = (maxFontSize + minFontSize) / 2.0
            
            let labelText: NSString = "00"
            
            let testStringWidth = labelText.size(
                withAttributes: [NSAttributedString.Key.font: UIFont.ttmFontBoldOfSize(fontSizeAverage)]
                ).width
            
            textAndLabelHeightDiff = width - testStringWidth
            
            if (fontSizeAverage == minFontSize || fontSizeAverage == maxFontSize) {
                if (textAndLabelHeightDiff < 0.0) {
                    return UIFont.ttmFontBoldOfSize(fontSizeAverage - 1.0)
                }
                return UIFont.ttmFontBoldOfSize(fontSizeAverage)
            }
            
            if (textAndLabelHeightDiff < 0.0) {
                maxFontSize = fontSizeAverage - 1.0
            } else if (textAndLabelHeightDiff > 0.0) {
                minFontSize = fontSizeAverage + 1.0
            } else {
                return UIFont.ttmFontBoldOfSize(fontSizeAverage)
            }
        }
        return UIFont.ttmFontBoldOfSize(trunc(maxFontSize))
    }
    
    @objc func touchDown(_ sender: UIButton) {
        self.isHighlighted = true
    }

    @objc func touchUpInside(_ sender: UIButton) {
        self.isHighlighted = false
    }

    @objc func touchUpOutsideOrCancelled(_ sender: UIButton) {
        self.isHighlighted = false
    }
    
    func update(_ match: TTMMatch, player: TTMMatchPlayer, animated: Bool) {
        self.match = match
        self.player = player
        
        self.defaultColor = player.color()
        self.borderColor = player.color()
        
        let animationBlock = {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.updateColors()
            strongSelf.backgroundView.layer.borderColor = player.color().cgColor
            
            let score = match.currentPlayerScore(player)
            strongSelf.label.text = String(score)
            
            let games = match.gamesScore(player)
            strongSelf.gamesLabel.text = String(games)
            
            if match.matchFinished || match.gameFinished {
                strongSelf.currentColor = UIColor.clear
                strongSelf.backgroundView.layer.borderWidth = 0.0
            } else {
                strongSelf.backgroundView.layer.borderWidth = 4.0
                
                if let matchServe = match.serve {
                    let serve = matchServe.rawValue == player.rawValue
                    
                    if serve {
                        strongSelf.currentColor = strongSelf.defaultColor
                    } else {
                        strongSelf.currentColor = UIColor.clear
                    }
                } else {
                    strongSelf.currentColor = UIColor.clear
                }
            }
        }
        
        if (animated) {
            let initialHeight = self.bounds.height
            let finalHeight = self.backgroundView.layer.cornerRadius*2.5
            let initialWidth = self.bounds.width
            let finalWidth = self.backgroundView.layer.cornerRadius*2.5
            
            let animationDuration = secondsToDeclineTaps
            let animationCycle = animationDuration/2.0
            let animationLabel = animationDuration/3.0
            
            self.gamesLabel.isHidden = true
            self.undoButton.isHidden = true
            
            UIView.animate(withDuration: animationCycle, delay: 0.0, options: [], animations: { [weak self] in
                
                guard let strongSelf = self else { return }
                
                strongSelf.backgroundView.bounds = CGRect(x: 0.0, y: 0.0, width: finalWidth, height: finalHeight)
                
                }, completion: { [weak self] (finished) in
                    animationBlock()
                    UIView.animate(withDuration: animationCycle, delay: 0.0, options: [], animations: { [weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.backgroundView.bounds = CGRect(x: 0.0, y: 0.0, width: initialWidth, height: initialHeight)
                        }, completion: { [weak self] (finished) in
                            guard let strongSelf = self else { return }
                            strongSelf.gamesLabel.isHidden = false
                            strongSelf.undoButton.isHidden = false
                    })
                    
                    UIView.animate(withDuration: animationLabel, delay: animationCycle - animationLabel, options: [], animations: {[weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.label.alpha = 1.0
                        }, completion: nil)
            })
            
            UIView.animate(withDuration: animationLabel, animations: {[weak self] in
                guard let strongSelf = self else { return }
                strongSelf.label.alpha = 0.0
                })
        } else {
            animationBlock()
        }
    }
    
    fileprivate func updateColors() {
        if let match = self.match, let player = self.player {
            let hasMatchServe = match.serve != nil
            var playerServe = false
            if let matchServe = match.serve {
                playerServe = matchServe.rawValue == player.rawValue
            }
            let filled = playerServe || match.matchFinished || match.gameFinished
            
            var labelColor = self.isHighlighted ? (self.defaultColor ?? UIColor.white).opaqueColor(0.5) : (!filled ? self.defaultColor : UIColor.white)
            var subtitleColor = labelColor
            if !hasMatchServe {
                labelColor = labelColor?.withAlphaComponent(0.2)
                subtitleColor = UIColor.clear
            }
            self.label.textColor = labelColor
            self.gamesLabel.textColor = subtitleColor
            
            self.undoButton?.backgroundColor = (self.isHighlighted || filled) ? UIColor.clear : UIColor.ttmGrayColor.withAlphaComponent(0.2)
            self.undoButton?.setImage(self.undoDefaultImage?.tinted(with: (self.isHighlighted || filled) ? UIColor.white.withAlphaComponent(0.5) : UIColor.ttmGrayColor), for: .normal)
            self.undoButton.alpha = hasMatchServe ? 1.0 : 0.0
        }
    }
}
