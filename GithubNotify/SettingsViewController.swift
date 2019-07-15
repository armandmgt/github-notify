//
//  SettingsViewController.swift
//  GithubNotify
//
//  Created by Armand Mégrot on 7/10/19.
//  Copyright © 2019 Armand Mégrot. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController, NSTextFieldDelegate {
    var delegate: AppDelegate?
    
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var accessTokenField: NSSecureTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        usernameField.becomeFirstResponder()
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
        
        delegate = NSApplication.shared.delegate as? AppDelegate
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        self.parent?.view.window?.title = self.title!
    }

    @IBAction func moveToAccessToken(_ sender: NSTextField) {
        accessTokenField.becomeFirstResponder()
    }
    
    @IBAction func saveCredentials(_ sender: Any) {
        delegate?.credentials.username = usernameField.stringValue
        delegate?.credentials.accessToken = accessTokenField.stringValue
        print("In saveCredentials:")
        print(delegate?.credentials.username ?? "nil")
        print(delegate?.credentials.accessToken ?? "nil")
        do {
            try delegate?.storeCredentials()
        } catch {
            NSAlert(error: error).runModal()
        }
    }
    
    @IBAction func openPersonalAccessTokenUrl(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/settings/tokens")!)
    }
}
