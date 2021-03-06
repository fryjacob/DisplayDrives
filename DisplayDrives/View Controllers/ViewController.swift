//
//  ViewController.swift
//  DisplayDrives
//
//  Created by Jake Fry on 4/3/18.
//  Copyright © 2018 Jake Fry. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    
    /*
     TODO:
        []  Check the size of the target drive to make sure the image will fit
        []  Add option to encrypt, take passwords, check they match.
        []  Make sure it works with\ spaces and\ escpape characters in file paths
        []  Reset fields on completion, show message
     
     
 
     */
    // Variables
    let filemanager = FileManager.default

    var filesList: [URL] = []
    var mountedVolumes: [URL] = []
    var sourcePath: String = ""
    var targetPath: String = ""
    
    
    var selectedSource: URL? {
        didSet {
            guard let sourceURL = selectedSource else {
                return
            }
            print("Source: \(sourceURL)")
            sourcePath = sourceURL.path
        }
    }
    
    var selectedTarget: URL? {
        didSet {
            guard let targetURL = selectedTarget else {
                return
            }
            print("Target: \(targetURL)")
            targetPath = targetURL.path
        }
    }
    // Outlets

    @IBOutlet weak var sourceTableView: NSTableView!
    @IBOutlet weak var targetTableView: NSTableView!
    @IBOutlet weak var encryptButton: NSButton!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var confirmField: NSSecureTextField!
    
    
    // Actions


    @IBAction func okButton(_ sender: NSButton) {
        print("Clone \(sourcePath) to \(targetPath)")
        
//        let path = "/usr/bin/hdiutil"
//        let arguments = ["create", "-srcfolder", "\(sourcePath)", "\(targetPath)/test.dmg", "-ov", "-verbose"]
//        print("\(path) \(arguments)")
//        sender.isEnabled = false
//        let task = Process.launchedProcess(launchPath: path, arguments: arguments)
//        task.waitUntilExit()
//        sender.isEnabled = true
        
        if encryptButton.state == NSControl.StateValue.on {
            print("Encrypted")
            if passwordField.stringValue == confirmField.stringValue {
                print("passwords match")
                
                
                        let path = "/usr/bin/hdiutil"
                        let arguments = ["create", "-srcfolder", "\(sourcePath)", "-encryption", "-stdinpass", "\(targetPath)/test.dmg", "-ov"]
                        print("\(path) \(arguments)")
                        sender.isEnabled = false
                
//                        Not sure if this works...
                        var task =  Process.launchedProcess(launchPath: "/bin/echo", arguments: ["-n", passwordField.stringValue, "|"])
                        task = Process.launchedProcess(launchPath: path, arguments: arguments)
                        task.waitUntilExit()
                        sender.isEnabled = true
            } else {
                print("no match")
            }
        } else {
            print("Not encrypted")

            
        }
        
        
        
    }
    
    @IBAction func exitButton(_ sender: NSButton) {
        NSApplication.shared.terminate(self)
    }
    
//    func reloadFileList() {
//        sourceTableView.reloadData()
//        targetTableView.reloadData()
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mountedVolumes = contentsOf(folder: URL(fileURLWithPath: "/Volumes/"))

        sourceTableView.delegate = self
        sourceTableView.dataSource = self
        
        targetTableView.delegate = self
        targetTableView.dataSource = self
        
        // Do any additional setup after loading the view.
    }

}

extension ViewController {
    
    func contentsOf(folder: URL) -> [URL] {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
            let urls = contents.map {
                return folder.appendingPathComponent($0)
            }
            return urls
        } catch {
            return []
        }
    }
}

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return mountedVolumes.count
    }
}
    
extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        
        let item = mountedVolumes[row]
        let fileIcon = NSWorkspace.shared.icon(forFile: item.path)
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("NameCellID"), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = item.lastPathComponent
            cell.imageView?.image = fileIcon
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        let tableView = notification.object as! NSTableView
        if let identifier = tableView.identifier, identifier == NSUserInterfaceItemIdentifier("sourceTableView") {
            if sourceTableView.selectedRow < 0 {
                selectedSource = nil
                return
            }
            selectedSource = mountedVolumes[sourceTableView.selectedRow]
        }
    
        if let identifier = tableView.identifier, identifier == NSUserInterfaceItemIdentifier("targetTableView") {
            if targetTableView.selectedRow < 0 {
                selectedTarget = nil
                return
            }
            selectedTarget = mountedVolumes[targetTableView.selectedRow]
        }

    }
}








