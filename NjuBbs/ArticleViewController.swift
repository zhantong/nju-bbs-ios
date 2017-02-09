//
//  ArticleViewController.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/15.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import UIKit

class ArticleViewController: UIViewController {
    var viaSegue = ""
    @IBOutlet weak var ContentScrollView: UIScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let asnode = ASTableViewController()
        asnode.viaSegue = viaSegue
        self.addChildViewController(asnode)
        ContentScrollView.addSubview(asnode.view)
        asnode.didMove(toParentViewController: self)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
