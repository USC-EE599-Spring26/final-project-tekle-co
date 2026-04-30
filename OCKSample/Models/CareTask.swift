//
//  CareTask.swift
//  OCKSample
//
//  Created by Cursor on 3/24/26.
//

import Foundation

protocol CareTask {
    var id: String { get }
    var priority: Int { get }
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
