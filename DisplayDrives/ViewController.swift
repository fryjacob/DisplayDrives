//
//  ViewController.swift
//  DisplayDrives
//
//  Created by Jake Fry on 4/3/18.
//  Copyright © 2018 Jake Fry. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var sourceTableView: NSScrollView!
    @IBOutlet weak var targetTableView: NSScrollView!
    
    @IBAction func okButton(_ sender: Any) {
    }
    @IBAction func exitButton(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

