//
//  CareTask.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/12/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

//
//  CareTask.swift
//  OCKSample
//
//  Created by Corey Baker on 3/3/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import Foundation

protocol CareTask {
    var id: String { get }
    var userInfo: [String: String]? { get set }
    var card: CareKitCard { get set }
    var priority: Int { get set }
}

extension CareTask {
    var card: CareKitCard {
        get {
            guard let cardInfo = userInfo?[Constants.card],
                  let careKitCard = CareKitCard(rawValue: cardInfo) else {
                return .simple
            }
            return careKitCard
        }
        set {
            if userInfo == nil { userInfo = .init() }
            userInfo?[Constants.card] = newValue.rawValue
        }
    }

    var priority: Int {
        get {
            guard let priorityInfo = userInfo?[Constants.priority],
                  let priority = Int(priorityInfo) else {
                return 100
            }
            return priority
        }
        set {
            if userInfo == nil { userInfo = .init() }
            userInfo?[Constants.priority] = String(newValue)
        }
    }
}

extension Array where Element == any CareTask {
    func sortedByPriority() -> [any CareTask] {
        sorted { lhs, rhs in
            if lhs.priority == rhs.priority {
                return lhs.id < rhs.id
            }
            return lhs.priority < rhs.priority
        }
    }
}
