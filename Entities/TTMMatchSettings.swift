//
//  TTMMatchSettings.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 24.07.16.
//

import Foundation

struct TTMMatchSettings: Equatable {

    let servesCount: Int = 2
    let minServesCount: Int = 1

    var pointCount: Int = 11
    var gameCount: Int = 7

    init(json: [String: Any]?) {
        if let count = json?["pointCount"] as? Int {
            self.pointCount = count
        }
        if let count = json?["gameCount"] as? Int {
            self.gameCount = count
        }
    }

    func toJson() -> [String: Any] {
        return ["pointCount": self.pointCount, "gameCount": self.gameCount]
    }
}
