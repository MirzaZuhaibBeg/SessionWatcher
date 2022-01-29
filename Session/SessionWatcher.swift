//
//  SessionWatcher.swift
//  SessionWatcher
//
//  Created by Mirza Zuhaib Beg on 2022-01-23.
//

import Foundation

protocol WorkItemProvider {
    func workItem(actionBlock: @escaping () -> ()) -> DispatchWorkItem?
}

class DefaultWorkItemProvider: WorkItemProvider {
    func workItem(actionBlock: @escaping () -> ()) -> DispatchWorkItem? {
        
        let workItem = DispatchWorkItem{
            actionBlock()
        }

        return workItem
    }
}


class SessionWatcher {
    private var workItemProvider: WorkItemProvider
    private var workItem: DispatchWorkItem?
    private let sessionTime: TimeInterval
    private let queue: DispatchQueue

    var onTimeExceeded: (() -> Void)?

    init(sessionTime: TimeInterval = 5, workItemProvider: WorkItemProvider, queue: DispatchQueue) {
        self.workItemProvider = workItemProvider
        self.sessionTime = sessionTime
        self.queue = queue
    }

    func start() {
        guard self.workItem == nil else {
            return
        }

        self.workItem = self.workItemProvider.workItem(actionBlock: { [weak self] in
            if let strongSelf = self {
                strongSelf.onTimeExceeded!()
            }
        })

        self.queue.asyncAfter(deadline: .now() + self.sessionTime) { [weak self] in
            if let strongSelf = self {
                strongSelf.queue.async(execute: (strongSelf.workItem)!)
            }
        }
    }

    func receivedUserAction() {
        guard self.workItem != nil else {
            return
        }

        self.workItem?.cancel()

        self.workItem = self.workItemProvider.workItem(actionBlock: { [weak self] in
            if let strongSelf = self {
                strongSelf.onTimeExceeded!()
            }
        })

        self.queue.asyncAfter(deadline: .now() + self.sessionTime) { [weak self] in
            if let strongSelf = self {
                strongSelf.queue.async(execute: (strongSelf.workItem)!)
            }
        }
    }

    func stop() {
        guard self.workItem != nil else {
            return
        }

        self.workItem?.cancel()
    }
}

