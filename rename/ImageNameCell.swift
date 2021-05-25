//
//  ImageNameCell.swift
//  rename
//
//  Created by quan on 2021/3/19.
//

import Cocoa

class ImageNameCell: NSTableCellView, NSTextFieldDelegate {
    static let insertNewlineNotification = "com.dq.NSTableCellView.insertNewline"

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField?.delegate = self
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        let cmdStr = NSStringFromSelector(commandSelector)
        if cmdStr == "insertNewline:" {
            let newName = textView.string
            NotificationCenter.default.post(name: NSNotification.Name(ImageNameCell.insertNewlineNotification), object: newName)
            return false
        }
        return false
    }
}
