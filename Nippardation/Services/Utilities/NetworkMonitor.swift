//
//  NetworkMonitor.swift
//  Nippardation
//
//  Phase 0: Network connectivity monitoring utility
//

import Foundation
import Network
import Combine

/// Monitors network connectivity status
/// Publishes changes to connectivity state for reactive UI updates
@MainActor
final class NetworkMonitor: ObservableObject {

    // MARK: - Published Properties

    /// Whether the network is currently available
    @Published private(set) var isConnected: Bool = true

    /// The type of network connection
    @Published private(set) var connectionType: ConnectionType = .unknown

    /// Whether the connection is expensive (cellular, hotspot)
    @Published private(set) var isExpensive: Bool = false

    /// Whether the connection is constrained (low data mode)
    @Published private(set) var isConstrained: Bool = false

    // MARK: - Connection Type

    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case wiredEthernet = "Ethernet"
        case unknown = "Unknown"
    }

    // MARK: - Private Properties

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var isMonitoring = false

    // MARK: - Initialization

    init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Monitoring

    /// Starts monitoring network changes
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateConnectionStatus(from: path)
            }
        }

        monitor.start(queue: queue)
    }

    /// Stops monitoring network changes
    func stopMonitoring() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }

    // MARK: - Private Methods

    private func updateConnectionStatus(from path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .unknown
        }
    }

    // MARK: - Convenience Methods

    /// Returns a publisher that emits when connection status changes
    var connectionStatusPublisher: AnyPublisher<Bool, Never> {
        $isConnected.eraseToAnyPublisher()
    }

    /// Waits for network to become available (with timeout)
    /// - Parameter timeout: Maximum time to wait
    /// - Returns: True if network became available, false if timed out
    func waitForConnection(timeout: TimeInterval = 30) async -> Bool {
        if isConnected { return true }

        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            var isResolved = false

            // Set up timeout
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if !isResolved {
                    isResolved = true
                    cancellable?.cancel()
                    continuation.resume(returning: false)
                }
            }

            // Listen for connection
            cancellable = $isConnected
                .dropFirst()
                .filter { $0 }
                .first()
                .sink { connected in
                    if !isResolved {
                        isResolved = true
                        timeoutTask.cancel()
                        continuation.resume(returning: connected)
                    }
                }
        }
    }
}

// MARK: - Preview Support

extension NetworkMonitor {

    /// Creates a mock monitor that's always connected
    static var alwaysConnected: NetworkMonitor {
        let monitor = NetworkMonitor()
        // Note: The actual NWPathMonitor will update these values
        // In previews, we rely on the default values (connected = true)
        return monitor
    }

    /// Creates a mock monitor that's always disconnected
    static var alwaysDisconnected: NetworkMonitor {
        let monitor = NetworkMonitor()
        monitor.stopMonitoring()
        // Force disconnected state for previews
        Task { @MainActor in
            monitor.isConnected = false
            monitor.connectionType = .unknown
        }
        return monitor
    }
}
