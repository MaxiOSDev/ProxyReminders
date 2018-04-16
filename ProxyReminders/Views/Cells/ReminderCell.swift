//
//  ReminderCell.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import UIKit

class ReminderCell: UITableViewCell {
    // Custom Cell 
    @IBOutlet weak var reminderBubble: UIButtonX!
    @IBOutlet weak var textView: UITextView!
    
    weak var delegate: ReminderCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    @IBAction func reminderDetail(_ sender: UIButton) {
        delegate?.buttonCloseTapped(cell: self)
    }
    

}
