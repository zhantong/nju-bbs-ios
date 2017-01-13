//
//  BoardLabel.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/13.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import UIKit

class BoardLabel: UILabel {
    var scale: CGFloat = 0.0 {
        didSet {
            textColor = UIColor(red: scale, green: 0, blue: 0, alpha: 1)
            let s: CGFloat = 1 + scale * CGFloat(0.3)
            transform = CGAffineTransform(scaleX: s, y: s)
        }
    }
    var type: Int = 0
    var url: String = ""
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
