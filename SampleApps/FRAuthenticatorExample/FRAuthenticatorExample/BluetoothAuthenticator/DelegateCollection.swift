import Foundation

class DelegateCollection<T> {
    private var delegates: [WeakDelegate] = []
    
    func add(_ delegate: AnyObject) {
        delegates.removeAll { $0.delegate == nil }
        delegates.append(WeakDelegate(delegate))
    }
    
    func remove(_ delegate: AnyObject) {
        guard let index = delegates.firstIndex(where: { $0.delegate === delegate }) else { return }
        delegates.remove(at: index)
    }
    
    func notify(_ task: (T) -> ()) {
        delegates.compactMap({ $0.delegate as? T }).forEach(task)
    }
    
    private class WeakDelegate {
        weak var delegate: AnyObject?
        
        init(_ delegate: AnyObject) {
            self.delegate = delegate
        }
    }
}
