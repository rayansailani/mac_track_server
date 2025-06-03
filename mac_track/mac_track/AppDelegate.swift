//  AppDelegate.swift
//  mac_track
//
//  Created by Sailani, Mohammed Rayan on 03/06/25.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var webSocketServer: WebSocketServer?
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start WebSocket server on launch
        webSocketServer = WebSocketServer()
        webSocketServer?.start(port: 9000)
        print("App launched!")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Stop WebSocket server on termination
        webSocketServer?.stop()
        print("App will terminate.")
    }
}
