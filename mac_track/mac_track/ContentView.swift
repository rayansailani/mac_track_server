//
//  ContentView.swift
//  mac_track
//
//  Created by Sailani, Mohammed Rayan on 03/06/25.
//

import SwiftUI
import Network
import NIO
import NIOHTTP1

struct ContentView: View {
    @State private var serverStarted = false
    @State private var serverURL: String = "" // Initialize as an empty string
    @State private var renderer: ClientRenderer? = nil
    @State private var localIP: String? = nil
    let port: Int = 8080

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Mac Trackpad Remote")
                .font(.title)
            Button(action: startServer) {
                Text(serverStarted ? "Server Running" : "Start HTTP Server")
            }
            .disabled(serverStarted)
            if !serverURL.isEmpty {
                Text("Open this link on your phone:")
                Text(serverURL)
                    .font(.headline)
                    .foregroundColor(.blue)
                Button(action: {
                    if !serverURL.isEmpty {
                        print("Copy URL button pressed. serverURL: \(serverURL)")
                        NSPasteboard.general.setString(serverURL, forType: .string)
                    } else {
                        print("Copy URL button pressed, but serverURL is empty.")
                    }
                }) {
                    Text("Copy URL")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .onAppear {
            fetchLocalIP { ip in
                self.localIP = ip
            }
        }
    }

    func startServer() {
        let renderer = ClientRenderer(port: port)
        renderer.start()
        self.renderer = renderer
        self.serverURL = "Starting..." // Temporary placeholder
        self.serverStarted = true

        // Poll for the server URL until it is resolved
        DispatchQueue.global().async {
            while renderer.serverURL.isEmpty {
                usleep(100_000) // Sleep for 100ms to avoid busy-waiting
            }
            DispatchQueue.main.async {
                self.serverURL = renderer.serverURL
            }
        }
    }

    func fetchLocalIP(completion: @escaping (String?) -> Void) {
        var address: String?
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                let interfaces = path.availableInterfaces.filter { $0.type == .wifi || $0.type == .wiredEthernet }
                for interface in interfaces {
                    let params = NWParameters()
                    params.requiredInterface = interface
                    let endpoint = NWEndpoint.hostPort(host: .ipv4(IPv4Address("8.8.8.8")!), port: 80)
                    let conn = NWConnection(to: endpoint, using: params)
                    conn.stateUpdateHandler = { state in
                        if case .ready = state {
                            if let local = conn.currentPath?.localEndpoint, case let .hostPort(host, _) = local {
                                address = host.debugDescription
                                conn.cancel()
                                monitor.cancel()
                                completion(address)
                            }
                        }
                    }
                    conn.start(queue: .global())
                }
            } else {
                completion(nil)
            }
        }
        monitor.start(queue: .global())
    }
}

#Preview {
    ContentView()
}
