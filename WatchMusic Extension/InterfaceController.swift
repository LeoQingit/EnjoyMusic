//
//  InterfaceController.swift
//  WatchMusic Extension
//
//  Created by Leo Qin on 2019/9/23.
//  Copyright © 2019 Qin Leo. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var mainTable: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        mainTable.setNumberOfRows(2, withRowType: "mainTableCell")
        let cell = mainTable.rowController(at: 0) as! WatchMainCell
//        cell.iconImageView.setImage(<#T##image: UIImage?##UIImage?#>)
        cell.titleLabel.setText("Demo")
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
