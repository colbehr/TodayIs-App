//
//  DetailsViewController.swift
//  TodayIs
//
//  Created by Jonathan Cho on 5/12/17.
//  Copyright © 2017 Coding Dojo. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {
    var passTitle: String?
    var passText: String?
    @IBOutlet weak var pagetitle: UILabel!
    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        pagetitle.text = passTitle
        textView.text = passText
        self.view.layer.borderWidth = 5.0
        self.view.layer.borderColor = UIColor(red:0.93,green:0.51,blue:0.23,alpha:1.0).cgColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
