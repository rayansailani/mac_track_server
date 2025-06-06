import Foundation
import NIO
import NIOHTTP1
import Network
import SystemConfiguration

class ClientRenderer {
    private var group: MultiThreadedEventLoopGroup?
    private var channel: Channel?
    private let port: Int
    var serverURL: String = ""

    init(port: Int = 8080) {
        self.port = port
    }

    func start() {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let bootstrap = ServerBootstrap(group: group!)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(ClientHTTPHandler())
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

        DispatchQueue.global().async {
            do {
                self.channel = try bootstrap.bind(host: "0.0.0.0", port: self.port).wait()
                // Log the IP address for debugging purposes
                if let ip = self.getLANIPAddress() {
                    print("LAN IP Address: \(ip)")
                    print("Open this link on your phone: http://\(ip):\(self.port)/trackpad.html")
                    self.serverURL = "http://\(ip):\(self.port)/trackpad.html"
                } else {
                    print("Unable to fetch LAN IP Address")
                    print("Open this link on your phone: http://localhost:\(self.port)/trackpad.html")
                }
            } catch {
                print("Failed to start HTTP server: \(error)")
            }
        }
    }

    func stop() {
        try? channel?.close().wait()
        try? group?.syncShutdownGracefully()
    }

    func getLANIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family

                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    if let name = String(cString: interface!.ifa_name, encoding: .utf8),
                       name == "en0" { // Wi-Fi interface
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface!.ifa_addr, socklen_t(interface!.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }
}

final class ClientHTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let req = self.unwrapInboundIn(data)
        switch req {
        case .head(let head):
            if head.uri == "/trackpad.html" || head.uri == "/" {
                if let htmlURL = Bundle.main.url(forResource: "trackpad", withExtension: "html"),
                   let htmlData = try? Data(contentsOf: htmlURL) {
                    var buffer = context.channel.allocator.buffer(capacity: htmlData.count)
                    buffer.writeBytes(htmlData)
                    let headers = HTTPHeaders([
                        ("Content-Type", "text/html; charset=utf-8"),
                        ("Content-Length", "\(htmlData.count)")
                    ])
                    let head = HTTPResponseHead(version: head.version, status: .ok, headers: headers)
                    context.write(self.wrapOutboundOut(.head(head)), promise: nil)
                    context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
                    context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
                } else {
                    send404(context: context, version: head.version)
                }
            } else {
                send404(context: context, version: head.version)
            }
        case .body, .end:
            break
        }
    }

    private func send404(context: ChannelHandlerContext, version: HTTPVersion) {
        let body = "404 Not Found"
        var buffer = context.channel.allocator.buffer(capacity: body.utf8.count)
        buffer.writeString(body)
        let headers = HTTPHeaders([
            ("Content-Type", "text/plain"),
            ("Content-Length", "\(body.utf8.count)")
        ])
        let head = HTTPResponseHead(version: version, status: .notFound, headers: headers)
        context.write(self.wrapOutboundOut(.head(head)), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}
