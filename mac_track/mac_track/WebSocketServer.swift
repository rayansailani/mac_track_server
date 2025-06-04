//  WebSocketServer.swift
//  mac_track
//
//  Created by Sailani, Mohammed Rayan on 03/06/25.
//
//  Minimal WebSocket server using SwiftNIO for macOS app

import Foundation
import NIO
import NIOHTTP1
import NIOWebSocket
import CoreGraphics
import AppKit 

// MARK: - HTTPHandler for WebSocket upgrade
final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart

    private let upgrader: NIOWebSocketServerUpgrader

    init(upgrader: NIOWebSocketServerUpgrader) {
        self.upgrader = upgrader
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // No-op: Upgrade is handled by the pipeline
    }
}


class WebSocketServer {
    private var group: MultiThreadedEventLoopGroup?
    private var channel: Channel?
    
    func start(port: Int = 9000) {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let upgrader = NIOWebSocketServerUpgrader(
            maxFrameSize: 1 << 14,
            shouldUpgrade: { (channel: Channel, req: HTTPRequestHead) in
                // You can inspect headers and accept/reject upgrade here
                return channel.eventLoop.makeSucceededFuture([:]) // No extra headers
            },
            upgradePipelineHandler: { channel, _ in
                // Add the WebSocket handler once upgraded
                return channel.pipeline.addHandler(WebSocketHandler())
            }
        )

        let bootstrap = ServerBootstrap(group: group!)
            .serverChannelOption(ChannelOptions.backlog, value: 256 as Int32)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1 as Int32)
            .childChannelInitializer { channel in
                // Set up HTTP server pipeline with WebSocket upgrader
                channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: (upgraders: [upgrader], completionHandler: { _ in }))
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1 as Int32)

        do {
            channel = try bootstrap.bind(host: "0.0.0.0", port: port).wait()
            print("✅ WebSocket server started on ws://0.0.0.0:\(port)")
        } catch {
            print("❌ Failed to start WebSocket server: \(error)")
        }
    }
    
    func stop() {
        try? channel?.close().wait()
        try? group?.syncShutdownGracefully()
        print("WebSocket server stopped.")
    }
}

final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)
        if case .text = frame.opcode, let text = frame.unmaskedDataAsString {
            if let jsonData = text.data(using: .utf8) {
                do {
                    let move = try JSONDecoder().decode(MoveEvent.self, from: jsonData)
                    print(move)
                    // Only process move events if type is "move" and both dx/dy are present
                    if move.type == "move", let dx = move.dx, let dy = move.dy, let screen = NSScreen.main {
                        let screenWidth = screen.frame.width
                        let screenHeight = screen.frame.height
                        let mappedDx = Double(dx) * Double(screenWidth)
                        let mappedDy = Double(dy) * Double(screenHeight)
                        CursorController.moveCursorBy(dx: mappedDx, dy: mappedDy)
                    }
                    // Handle click events
                    if move.type == "click", let button = move.button {
                        CursorController.emulateClick(button: button)
                    }
                    // You can add gesture handling here in the future
                } catch {
                    print("Received text: \(text)")
                }
            }
        }
    }
}

struct MoveEvent: Codable {
    let type: String
    let dx: Double?
    let dy: Double?
    let button: String?
    let gesture: String?
    let pinchDelta: Double?
    let timestamp: Double?
}

private extension WebSocketFrame {
    var unmaskedDataAsString: String? {
        guard let data = self.unmaskedData.getString(at: 0, length: self.unmaskedData.readableBytes) else { return nil }
        return data
    }
}
