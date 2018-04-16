//
//  ComposeCell.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import UIKit
import CoreData
class ComposeCell: UITableViewCell {
    // Custom Cell
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var composeButton: UIButtonX!
    @IBOutlet weak var detailButton: UIButton!
    
    var context = CoreDataStack().managedObjectContext
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textView.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        
    }
}

extension ComposeCell: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
