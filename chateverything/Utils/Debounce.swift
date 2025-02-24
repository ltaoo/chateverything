import Foundation

class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(_ block: @escaping () -> Void) {
        workItem?.cancel()
        
        let newWorkItem = DispatchWorkItem(block: block)
        workItem = newWorkItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
} 