import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "net.monitor")

    private(set) var isReachable: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isReachable = (path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }
}
