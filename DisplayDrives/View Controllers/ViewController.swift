//
//  ViewController.swift
//  Lifeboat
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
     []  Hide the details textView
     
     
     */
    // Variables
    
    let filemanager = FileManager.default
    
    var filesList: [URL] = []
    var mountedVolumes: [URL] = []
    var sourcePath: String = ""
    var targetPath: String = ""
    var sourceSize: Int64 = 0
    var targetCapacity: Int64 = 0
    
    @objc dynamic var isRunning = false
    var outputPipe:Pipe!
    var createImageTask:Process!
    
    var selectedSource: URL? {
        didSet {
            guard let sourceURL = selectedSource else {
                return
            }
            sourcePath = sourceURL.path
            print("Source: \(sourceURL)")
            
            // Find the size of the source volume
            do {
                let values = try sourceURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                let values1 = try sourceURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
                
                let capacity = Int64(values1.volumeTotalCapacity ?? 0)
                let available = values.volumeAvailableCapacityForImportantUsage ?? 0
                sourceSize = capacity - available
                print("Need: \(sourceSize)")
//                print("Free: \(available)")
//                print("Total: \(capacity)")
                
                
                

            } catch {
                print("Error retrieving capacity: \(error.localizedDescription)")
            }
            
            
        }
    }
    
    var selectedTarget: URL? {
        didSet {
            guard let targetURL = selectedTarget else {
                return
            }
            print("Target: \(targetURL)")
            targetPath = targetURL.path
            
            // Find the size of the target volume
            do {
                let values = try targetURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                let available = values.volumeAvailableCapacityForImportantUsage ?? 0
                targetCapacity = available
  
                 print("Have: \(available)")
                
                
            } catch {
                print("Error retrieving capacity: \(error.localizedDescription)")
            }
            
        }
    }
    // Outlets
    
    @IBOutlet weak var sourceTableView: NSTableView!
    @IBOutlet weak var targetTableView: NSTableView!
    @IBOutlet weak var encryptButton: NSButton!
    @IBOutlet weak var exitButton: NSButton!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var confirmField: NSSecureTextField!
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var outputText: NSTextView!
    @IBOutlet weak var passwordLabel: NSTextField!
    @IBOutlet weak var confirmLabel: NSTextField!
    @IBOutlet weak var showDetailsButton: NSButton!
    @IBOutlet weak var detailsLabel: NSTextField!
    @IBOutlet weak var detailsView: NSScrollView!
    @IBOutlet var mainView: NSView!
    
    
    // Actions
    
    
    @IBAction func hidePasswordField(_ sender: NSButton) {
        if encryptButton.state == NSControl.StateValue.on {
            passwordField.isHidden = false
            confirmField.isHidden = false
            passwordLabel.isHidden = false
            confirmLabel.isHidden = false
        } else {
            passwordField.isHidden = true
            confirmField.isHidden = true
            passwordLabel.isHidden = true
            confirmLabel.isHidden = true
            
        }
        
        
        
    }
    @IBAction func startTask(_ sender: NSButton) {
        print("Clone \(sourcePath) to \(targetPath)")
        
        startButton.isEnabled = false
        spinner.isHidden = false
        spinner.startAnimation(self)
        statusLabel.isHidden = false
        
        print(filemanager.componentsToDisplay(forPath: sourcePath)!)
        
        
        if targetCapacity > sourceSize {
        
            if encryptButton.state == NSControl.StateValue.on {
                
                print("Encrypted")
                if passwordField.stringValue == confirmField.stringValue {
                    print("passwords match")
                    //                let path = "/usr/bin/hdiutil"
                    //let arguments = ["create", "-srcfolder", "\(sourcePath)", "-encryption", "-stdinpass", "\(targetPath)/test.dmg", "-ov"]

                    let arguments = [passwordField.stringValue, "\(sourcePath)", "\(targetPath)/backupTest.dmg"]
                    print("\(arguments)")
                    runScript(arguments)
                    
                } else {
                    print("no match")
                    
                }
                
            } else {
                print("Not encrypted")
                
            }
            
        } else {
            print("Insufficient space on target volume.")
        }
    }
    
    @IBAction func exitButton(_ sender: NSButton) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func showDetails(_ sender: NSButton) {
        if showDetailsButton.state == NSControl.StateValue.on {
            self.detailsView.isHidden = false
            self.detailsLabel.stringValue = "Hide Details"
            
        } else {
            self.detailsView.isHidden = true
            self.detailsLabel.stringValue = "Show Details"
            
//            self.view.window?.setFrame(NSRect(x: 0, y: 0, width: 150, height: 500), display: true)
        }
    
    
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mountedVolumes = contentsOf(folder: URL(fileURLWithPath: "/Volumes/"))
        print(mountedVolumes)
        

        sourceTableView.delegate = self
        sourceTableView.dataSource = self
        
        targetTableView.delegate = self
        targetTableView.dataSource = self
        
        // Do any additional setup after loading the view.
    }
    
    func captureStandardOutputAndRouteToTextView(_ task:Process) {
        
        //1.
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        //2.
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        //3.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) {
            notification in
            
            //4.
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            //5.
            DispatchQueue.main.async(execute: {
                let previousOutput = self.outputText.string
                let nextOutput = previousOutput + "\n" + outputString
                self.outputText.string = nextOutput
                
                let range = NSRange(location:nextOutput.count,length:0)
                self.outputText.scrollRangeToVisible(range)
                
            })
            
            //6.
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
        
    }
    
}

extension ViewController {
    
    func contentsOf(folder: URL) -> [URL] {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
//            let keys: [URLResourceKey] = [.volumeNameKey]
//            let contents1 = try fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keySelection, options: [])
            let urls = contents.map {
                return folder.appendingPathComponent($0)
            }
            return urls
        } catch {
            return []
        }
    }
    
    func runScript(_ arguments:[String]) {
        isRunning = true
        
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        
        
        taskQueue.async {
            
            
            //1.
            guard let path = Bundle.main.path(forResource: "CreateImageScript",ofType:"command") else {
                print("Unable to locate CreateImageScript.command")
                return
            }
            
            //2.
            self.createImageTask = Process()
            self.createImageTask.launchPath = path
            self.createImageTask.arguments = arguments
            
            //3.
            self.createImageTask.terminationHandler = {
                
                task in
                DispatchQueue.main.async(execute: {
                    self.startButton.isEnabled = true
                    self.spinner.stopAnimation(self)
                    self.spinner.isHidden = true
                    self.statusLabel.stringValue = "Image Complete"
                    self.isRunning = false
                    self.passwordField.stringValue = ""
                    self.confirmField.stringValue = ""
                    self.exitButton.isEnabled = false
                    print("Complete")
                    
                    
                    
                })
                
            }
            
            //TODO - Output Handling
            self.captureStandardOutputAndRouteToTextView(self.createImageTask)
            
            //4.
            self.createImageTask.launch()
            
            //5.
            self.createImageTask.waitUntilExit()
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








