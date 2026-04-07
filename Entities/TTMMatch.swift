//
//  TTMMatch.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 04.05.16.
//

import UIKit

enum TTMMatchPlayer: Int {
    case green = 1
    case blue = 2
    
    func inverse() -> TTMMatchPlayer {
        if self == .green {
            return .blue
        }
        return .green
    }
    
    func color() -> UIColor {
        switch self {
        case .green:
            return UIColor.ttmGreenColor
        case .blue:
            return UIColor.ttmBlueColor
        }
    }
    
    static func rand() -> TTMMatchPlayer {
        let rand = arc4random()
        if rand % 2 == 0 {
            return .green
        }
        return .blue
    }
}

class TTMMatch: AnyObject {
    
    static var currentMatch: TTMMatch = {
        let result = TTMMatch()
        result.restore()
        return result
    }()
    
    var settings: TTMMatchSettings = TTMMatchSettings(json: nil) {
        didSet {
            if (self.matchFinished) {
                self.reset()
            } else {
                self.save()
            }
        }
    }
    
    var isStarted: Bool {
        return self.serve != nil
    }
    
    var players: [TTMMatchPlayer] {
        if self.gameScores.count % 2 == 0 || (self.isFinalGame() && self.isCurrentGamePassedHalf()) {
            return [.blue, .green]
        } else {
            return [.green, .blue]
        }
    }
    
    var gameScores: [[TTMMatchPlayer: Int]] = [[.green: 0, .blue: 0]] {
        didSet {
            self.save()
        }
    }
    
    var currentGameScore: [TTMMatchPlayer: Int] {
        get {
            return self.gameScores.last ?? [.green: 0, .blue: 0]
        }
        set {
            self.gameScores[self.gameScores.count - 1] = newValue
        }
    }
    
    var serve: TTMMatchPlayer? {
        get {
            guard let firstServe = self.firstServe else { return nil }
            let sumPoints = self.currentGameScore[.green]! + self.currentGameScore[.blue]!
            let firstServeInCurrentGame = self.gameScores.count % 2 == 1 ? firstServe : firstServe.inverse()
            
            var resultServesCount = self.settings.servesCount
            // больше-меньше
            if (sumPoints >= (self.settings.pointCount-1) * 2) {
                resultServesCount = self.settings.minServesCount
            }
            
            let round = resultServesCount * 2
            let remain = sumPoints % round
            if remain < resultServesCount {
                return firstServeInCurrentGame
            } else {
                return firstServeInCurrentGame.inverse()
            }
        }
    }
    var firstServe: TTMMatchPlayer? {
        didSet {
            self.save()
        }
    }
    fileprivate var history:[[[TTMMatchPlayer: Int]]] = [] {
        didSet {
            self.save()
        }
    }
    
    fileprivate func pushCurrentScoreToHistory() {
        var history = self.history
        history.append(self.gameScores)
        self.history = history
    }
    
    func currentPlayerScore(_ player: TTMMatchPlayer) -> Int {
        switch player {
        case .green:
            return self.currentGameScore[.green]!
        case .blue:
            return self.currentGameScore[.blue]!
        }
    }
    
    func isFinalGame() -> Bool {
        return self.gameScores.count == self.settings.gameCount
    }
    
    func isCurrentGamePassedHalf() -> Bool {
        let currentLeadingScore = max(self.currentGameScore[.green] ?? 0, self.currentGameScore[.blue] ?? 0)
        let halfWayScore = self.settings.pointCount / 2
        return currentLeadingScore >= halfWayScore
    }
    
    func gamesScore(_ player: TTMMatchPlayer) -> Int {
        var finishedGames = self.gameScores
        if !self.gameFinished {
            finishedGames.removeLast()
        }
        
        switch player {
        case .green:
            return finishedGames.filter({ $0[.green]! > $0[.blue]! }).count
        case .blue:
            return finishedGames.filter({ $0[.green]! < $0[.blue]! }).count
        }
    }
    
    func increasePlayerScore(_ player: TTMMatchPlayer) {
        switch player {
        case .green:
            self.currentGameScore[.green] = self.currentGameScore[.green]! + 1
        case .blue:
            self.currentGameScore[.blue] = self.currentGameScore[.blue]! + 1
        }
    }
    
    func restore() {
        let userDefaults = UserDefaults.standard
        if let dict = userDefaults.object(forKey: "TTMMatch") as? [String: Any] {
            self.settings = TTMMatchSettings(json: dict["settings"] as? [String: Any])
            
            var gameScores: [[TTMMatchPlayer: Int]] = []
            if let games = dict["games"] as? [[Int]] {
                for game in games {
                    if game.count == 2 {
                        gameScores.append([.green: game.first!, .blue: game.last!])
                    }
                }
            }
            self.gameScores = gameScores.count > 0 ? gameScores : [[.green: 0, .blue: 0]]
        
            if let firstServe = dict["firstServe"] as? String, let firstServeValue = Int(firstServe) {
                self.firstServe = TTMMatchPlayer(rawValue: firstServeValue)
            } else {
                self.firstServe = nil
            }
            
            var history: [[[TTMMatchPlayer: Int]]] = []
            if let historyArray = dict["history"] as? [[[Int]]] {
                for historyElement in historyArray {
                    var gameScores: [[TTMMatchPlayer: Int]] = []
                    for game in historyElement {
                        if game.count == 2 {
                            gameScores.append([.green: game.first!, .blue: game.last!])
                        }
                    }
                    history.append(gameScores)
                }
            }
            self.history = history
            
        }
        if (self.matchFinished) {
            self.reset()
        }
    }
    
    fileprivate func save() {
        let userDefaults = UserDefaults.standard
        var dict: [String: Any] = [:]

        var gameScores: [[Int]] = []
        for game in self.gameScores {
            gameScores.append([game[.green]!, game[.blue]!])
        }
        dict["games"] = gameScores

        if let firstServe = self.firstServe {
            dict["firstServe"] = String(firstServe.rawValue)
        }
        dict["settings"] = self.settings.toJson()

        var history: [[[Int]]] = []
        for historyElement in self.history {
            var gameScores: [[Int]] = []
            for game in historyElement {
                gameScores.append([game[.green]!, game[.blue]!])
            }
            history.append(gameScores)
        }
        dict["history"] = history

        userDefaults.set(dict, forKey: "TTMMatch")
    }
    
    fileprivate func clear() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "TTMMatch")
    }
    
    func reset() {
        self.firstServe = nil
        self.gameScores = [[.green: 0, .blue: 0]]
        self.history = []
    }
    
    func playerAction(_ player: TTMMatchPlayer) {
        if self.firstServe == nil {
            self.firstServe = player
            TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.tapServiceChanged)
        } else {
            self.pushCurrentScoreToHistory()
            
            let prevServe = self.serve
            let prevGamePoint = self.gamePoint
            
            if (self.gameFinished && !self.matchFinished) {
                self.gameScores.append([.green: 0, .blue: 0])
            } else {
                self.increasePlayerScore(player)
            }
            
            if (self.gameFinished) {
                TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.win)
            } else if (self.serve != prevServe) {
                TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.tapServiceChanged)
            } else {
                TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.tap)
            }
            
            if (self.gamePoint && !prevGamePoint) {
                TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.warning)
            }
        }
    }
    
    func undo() {
        TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.cancel)
        
        if let prevScore = self.history.last {
            self.gameScores = prevScore
            var history = self.history
            history.removeLast()
            self.history = history
        } else if self.firstServe != nil {
            self.firstServe = nil
        }
    }
    
    func canUndo() -> Bool {
        return self.history.count > 0
    }
    
    var gameFinished: Bool {
        get {
            let maxScore = max(self.currentGameScore[.green]!, self.currentGameScore[.blue]!)
            let minScore = min(self.currentGameScore[.green]!, self.currentGameScore[.blue]!)
            
            if (maxScore >= self.settings.pointCount && (maxScore-minScore)>=2) {
                return true
            }
            return false
        }
    }
    
    var matchFinished: Bool {
        get {
            let maxScore = max(self.gamesScore(.green), self.gamesScore(.blue))
            
            if (maxScore >= self.settings.gameCount/2 + 1) {
                return true
            }
            return false
        }
    }
    
    var gamePoint: Bool {
        get {
            let maxScore = max(self.currentGameScore[.green]!, self.currentGameScore[.blue]!)
            let minScore = min(self.currentGameScore[.green]!, self.currentGameScore[.blue]!)
            
            if (maxScore >= self.settings.pointCount-1 && (maxScore-minScore)>=1) {
                return true
            }
            return false
        }
    }
    
    var winner: TTMMatchPlayer? {
        get {
            if self.matchFinished {
                let player1Score = self.gamesScore(.green)
                let player2Score = self.gamesScore(.blue)
                
                if (player1Score > player2Score) {
                    return .green
                }
                return .blue
            }
            return nil
        }
    }
    
    var gameWinner: TTMMatchPlayer? {
        get {
            if self.gameFinished {
                let player1Score = self.currentPlayerScore(.green)
                let player2Score = self.currentPlayerScore(.blue)
                
                if (player1Score > player2Score) {
                    return .green
                }
                return .blue
            }
            return nil
        }
    }
}
