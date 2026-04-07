//
//  TTMGameCell.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 29.07.16.
//

import UIKit

class TTMGameCell: UITableViewCell {
    
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var container: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.clear
        self.container.layer.cornerRadius = 4.0
        self.leftLabel.textColor = UIColor.white
        self.rightLabel.textColor = UIColor.white
        self.leftLabel.font = UIFont.ttmFontHeavyOfSize(14.0)
        self.rightLabel.font = UIFont.ttmFontHeavyOfSize(14.0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func update(_ match: TTMMatch, gameIndex: Int, players: [TTMMatchPlayer]) {
        if (gameIndex < match.gameScores.count - 1) || (gameIndex == match.gameScores.count - 1 && match.gameFinished) {
            let game = match.gameScores[gameIndex]
            let player1Score = game[players[0]]!
            let player2Score = game[players[1]]!
            
            self.leftLabel.text = String(player1Score)
            self.rightLabel.text = String(player2Score)
            self.leftLabel.isHidden = false
            self.rightLabel.isHidden = false
            
            if player1Score > player2Score {
                self.leftLabel.alpha = 1.0
                self.rightLabel.alpha = 0.5
                self.container.backgroundColor = players[0].color()
                self.layer.borderColor = players[0].color().cgColor
            } else {
                self.rightLabel.alpha = 1.0
                self.leftLabel.alpha = 0.5
                self.container.backgroundColor = players[1].color()
                self.layer.borderColor = players[1].color().cgColor
            }
        } else {
            self.leftLabel.isHidden = true
            self.rightLabel.isHidden = true
            self.container.backgroundColor = UIColor.ttmGrayColor.withAlphaComponent(0.5)
            self.layer.borderColor = UIColor.ttmGrayColor.withAlphaComponent(0.5).cgColor
        }
        
        if match.gameFinished {
            self.container.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        }
    }
    
}
