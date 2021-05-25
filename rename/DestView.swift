//
//  DestView.swift
//  rename
//
//  Created by quan on 2021/3/12.
//

import Foundation
import AppKit

class DestView: NSView {
    static let dragNotificationName = "DestViewCustomDragNotificationName"
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("draggingEntered...")
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(red: 102/255.0, green: 139/255.0, blue: 139/255.0, alpha: 1).cgColor
        return NSDragOperation.every
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.wantsLayer = false
        self.layer?.backgroundColor = NSColor.clear.cgColor
        print("拖拽结束...")
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.wantsLayer = false
        self.layer?.backgroundColor = NSColor.clear.cgColor
        print("draggingExited...")
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("prepareForDragOperation")
        if let str = sender.draggingPasteboard.string(forType: NSPasteboard.PasteboardType.fileURL),
           let url = URL(string: str) {
            let fileManager = FileManager.default
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDir) {
                let obj = CustomDragInfo(url, isDir: isDir.boolValue)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: DestView.dragNotificationName), object: obj)
                return true
            }
            return false
        }
        return false
    }
}

class CustomDragInfo: NSObject {
    let url: URL
    let isDir: Bool
    
    init(_ url: URL, isDir: Bool) {
        self.url = url
        self.isDir = isDir
    }
}
