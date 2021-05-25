//
//  ViewController.swift
//  rename
//
//  Created by quan on 2021/3/12.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var toolBar: NSView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var bigImage: NSImageView!
    @IBOutlet weak var bigLabel: NSTextField!
    @IBOutlet weak var smallImage: NSImageView!
    @IBOutlet weak var smallLabel: NSTextField!
    
    @IBOutlet weak var prefixTF: NSTextField!
    @IBOutlet weak var remove1x: NSButton!
    
    var items = [CustomRenamePngInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        toolBar.wantsLayer = true
        toolBar.layer?.backgroundColor = NSColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1).cgColor
        tableView.delegate = self
        tableView.dataSource = self
        
        prefixTF.placeholderString = "auto_name"
        
        view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        
        NotificationCenter.default.addObserver(self, selector: #selector(dealDrag(noti:)), name: NSNotification.Name(rawValue: DestView.dragNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(editName(noti:)), name: NSNotification.Name(rawValue: ImageNameCell.insertNewlineNotification), object: nil)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func dealSelect(item: CustomRenamePngInfo) {
        if item.has3x {
            let bigImg = NSImage(contentsOfFile: item.path + "/" + item.name + "@3x.png")
            bigImage.image = bigImg?.resize(size: NSSize(width: 180, height: 180))
            bigLabel.stringValue = item.name + "@3x.png"
        }
        if item.has2x {
            let smallImg = NSImage(contentsOfFile: item.path + "/" + item.name + "@2x.png")
            smallImage.image = smallImg?.resize(size: NSSize(width: 120, height: 120))
            smallLabel.stringValue = item.name + "@2x.png"
        }
        if !item.has3x && !item.has2x {
            let img = NSImage(contentsOfFile: item.path + "/" + item.name + ".png")
            bigImage.image = img?.resize(size: NSSize(width: 180, height: 180))
            bigLabel.stringValue = item.name + ".png"
            smallImage.image = img?.resize(size: NSSize(width: 120, height: 120))
            smallLabel.stringValue = item.name + ".png"
        }
    }
    
    @objc
    func dealDrag(noti: Notification) {
        if let obj = noti.object as? CustomDragInfo, obj.isDir {
            var objects: [String:CustomRenamePngInfo] = [:]
            getPngPlainName(dirPath: obj.url.path, items: &objects)
            self.items = objects.values.map {$0}
            self.tableView.reloadData()
            if items.count > 0 {
                DispatchQueue.main.async {
                    self.tableView.selectRowIndexes(IndexSet(arrayLiteral: 0), byExtendingSelection: true)
                    self.dealSelect(item: self.items[0])
                }
            }
        }
    }
    
    @objc
    func editName(noti: Notification) {
        let selectedRow = tableView.selectedRow
        let newName = noti.object as! String
        
        changeName(for: &items[selectedRow], newName: newName)
        self.dealSelect(item: self.items[selectedRow])
    }
    
    private func getPngPlainName(dirPath: String, items: inout [String:CustomRenamePngInfo]) {
        let fm = FileManager.default
        var subDirs = [String]()
        if let contents = try? fm.contentsOfDirectory(atPath: dirPath) {
            for subpath in contents {
                var isdir: ObjCBool = false
                if fm.fileExists(atPath: dirPath + "/" + subpath, isDirectory: &isdir), isdir.boolValue {
                    subDirs.append(dirPath + "/" + subpath)
                }
                else {
                    if let info = getpngBasicInfo(pngName: subpath) {
                        let uniqueName = dirPath + "/" + info.0
                        if var obj = items[uniqueName] {
                            if info.1 { obj.has3x = true }
                            if info.2 { obj.has2x = true }
                            if info.3 { obj.has1x = true }
                            items[uniqueName] = obj
                        }
                        else {
                            let item = CustomRenamePngInfo(info.0, has3x: info.1, has2x: info.2, has1x: info.3, path: dirPath)
                            items[uniqueName] = item
                        }
                    }
                }
            }
        }
        
        for dir in subDirs {
            getPngPlainName(dirPath: dir, items: &items)
        }
    }
    
    
    private func getpngBasicInfo(pngName: String) -> (String, Bool, Bool, Bool)? {
        let is3x = pngName.hasSuffix("@3x.png")
        let is2x = pngName.hasSuffix("@2x.png")
        let is1x = (!is3x && !is2x && pngName.hasSuffix(".png"))
        var name: String
        if is3x || is2x {
            name = String(pngName[..<pngName.lastIndex(of: "@")!])
        }
        else if is1x {
            name = String(pngName[..<pngName.lastIndex(of: ".")!])
        }
        else {
            return nil
        }
        return (name, is3x, is2x, is1x)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func changeName(for item: inout CustomRenamePngInfo, newName: String) {
        if item.has3x {
            let oriPath = item.path + "/" + item.name + "@3x.png"
            let newPath =  item.path + "/" + newName + "@3x.png"
            try? FileManager.default.moveItem(atPath: oriPath, toPath: newPath)
        }
        if item.has2x {
            let oriPath = item.path + "/" + item.name + "@2x.png"
            let newPath =  item.path + "/" + newName + "@2x.png"
            try? FileManager.default.moveItem(atPath: oriPath, toPath: newPath)
        }
        
        if item.has1x {
            let oriPath = item.path + "/" + item.name + ".png"
            let newPath =  item.path + "/" + newName + ".png"
            
            if remove1x.state.rawValue == 1 {
                try? FileManager.default.trashItem(at: URL(fileURLWithPath: oriPath), resultingItemURL: nil)
            }
            else {
                try? FileManager.default.moveItem(atPath: oriPath, toPath: newPath)
            }
        }
        item.name = newName
    }
    
    private func delete(item: CustomRenamePngInfo) {
        if item.has3x {
            let filePath = item.path + "/" + item.name + "@3x.png"
            try? FileManager.default.trashItem(at: URL(fileURLWithPath: filePath), resultingItemURL: nil)
        }
        if item.has2x {
            let filePath = item.path + "/" + item.name + "@2x.png"
            try? FileManager.default.trashItem(at: URL(fileURLWithPath: filePath), resultingItemURL: nil)
        }
        if item.has1x {
            let filePath = item.path + "/" + item.name + ".png"
            try? FileManager.default.trashItem(at: URL(fileURLWithPath: filePath), resultingItemURL: nil)
        }
    }
    
    @IBAction func changeAll(_ sender: Any) {
        var prefix = prefixTF.stringValue == "" ? prefixTF.placeholderString! : prefixTF.stringValue
        prefix += "_"
        
        for index in 0..<items.count {
            changeName(for: &items[index], newName: "\(prefix)\(index)")
        }
        
        let selectedRow = tableView.selectedRow
        tableView.reloadData()
        guard selectedRow >= 0, selectedRow < items.count else {
            return
        }
       
        tableView.selectRowIndexes(IndexSet(arrayLiteral: selectedRow), byExtendingSelection: true)
        dealSelect(item: self.items[selectedRow])
    }
    
    @IBAction func showInFinder(_ sender: Any) {
        var row = tableView.selectedRow
        if row < 0 && items.count > 0 {
           row = 0
        }
        guard row >= 0, row < items.count else {
            return
        }
        let item = items[row]
        NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
    }
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImageNameCell"), owner: nil) as? NSTableCellView {
            let model = items[row]
            cell.textField?.stringValue = model.name
            cell.textField?.isEditable = true
            cell.textField?.isSelectable = true
            cell.imageView?.image = NSImage(contentsOfFile: model.path + "/" + model.name + "@3x.png")
            return cell
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let item = items[row]
        self.dealSelect(item: item)
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        print("keyDown + \(event)")
        let keyCode = event.keyCode
        switch keyCode {
        case 51:
            let row = tableView.selectedRow
            guard row >= 0, row < items.count else {
                return
            }
            let item = items.remove(at: row)
            delete(item: item)
            tableView.reloadData()
            let nextRow = row >= items.count ? 0 : row
            if items.count > 0 {
                tableView.selectRowIndexes(IndexSet(arrayLiteral: nextRow), byExtendingSelection: true)
                dealSelect(item: self.items[nextRow])
            }
        default:
            break
        }
    }
}


struct CustomRenamePngInfo: Hashable {
    var path: String
    var name: String
    var has3x: Bool = false
    var has2x: Bool = false
    var has1x: Bool = false
    
    init(_ name: String, has3x: Bool = false, has2x: Bool = false, has1x: Bool = false, path: String = "") {
        self.path = path
        self.name = name
        self.has3x = has3x
        self.has2x = has2x
        self.has1x = has1x
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name.hashValue + path.hashValue)
    }
}

extension NSImage {
    
    func resize(size: NSSize) -> NSImage {
        var targetFrame = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        let targetImage = NSImage(size: size)
        let sourceSize = self.size
        let ratioH = size.height / sourceSize.height
        let ratioW = size.width / sourceSize.width
        let ratio = min(ratioH, ratioW)
        
        let cropRect = NSRect(x: 0, y: 0, width: sourceSize.width, height: sourceSize.height)
        targetFrame.size.width = sourceSize.width * ratio
        targetFrame.size.height = sourceSize.height * ratio
        targetFrame.origin.x = floor((size.width - targetFrame.size.width)/2)
        targetFrame.origin.y = floor((size.height - targetFrame.size.height)/2)
         
        targetImage.lockFocus()
        self.draw(in: targetFrame, from: cropRect, operation: NSCompositingOperation.copy, fraction: 1.0, respectFlipped: true, hints: [NSImageRep.HintKey.interpolation : NSNumber(integerLiteral: Int(NSImageInterpolation.low.rawValue))])
        targetImage.unlockFocus()
        return targetImage
        
        /*
        let targetFrame = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        let targetImage = NSImage(size: size)
        let sourceSize = self.size
        let ratioH = size.height / sourceSize.height
        let ratioW = size.width / sourceSize.width


        var cropRect = NSZeroRect
        if (ratioH >= ratioW) {
            cropRect.size.width = floor (size.width / ratioH);
            cropRect.size.height = sourceSize.height;
        } else {
            cropRect.size.width = sourceSize.width;
            cropRect.size.height = floor(size.height / ratioW);
        }

        cropRect.origin.x = floor( (sourceSize.width - cropRect.size.width)/2 );
        cropRect.origin.y = floor( (sourceSize.height - cropRect.size.height)/2 );


        targetImage.lockFocus()
        self.draw(in: targetFrame, from: cropRect, operation: NSCompositingOperation.copy, fraction: 1.0, respectFlipped: true, hints: [NSImageRep.HintKey.interpolation : NSNumber(integerLiteral: Int(NSImageInterpolation.low.rawValue))])
        targetImage.unlockFocus()
        return targetImage
         */
    }
}

