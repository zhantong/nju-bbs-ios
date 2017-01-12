//
//  BoardsListTableViewController.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/12.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

struct BoardsListCellData {
    let board: String!
    let category: String!
    let name: String!
    let moderator: String!
    let boardUrl: String!
}
class BoardsListTableViewController: UITableViewController {
    let baseUrl = "http://bbs.nju.edu.cn"
    var cellDataList = [BoardsListCellData]()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        Alamofire.request(baseUrl + "/bbsall").responseData(completionHandler: {
            response in
            print(response.request!)
            print(response.response!)
            print(response.data!)
            if let data = response.result.value, let content = String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) {
                if let doc = HTML(html: content, encoding: .utf8) {
                    for row in doc.xpath("//table/tr[position()>1]") {
                        print(row.text)
                        let board = row.at_xpath("./td[2]")
                        let category = row.at_xpath("./td[3]")
                        let name = row.at_xpath("./td[4]")
                        let moderator = row.at_xpath("./td[5]")
                        let boardUrl = board?.at_xpath("./a/@href")
                        self.cellDataList.append(BoardsListCellData(board: board?.text, category: category?.text, name: name?.text, moderator: moderator?.text, boardUrl: boardUrl?.text))
                    }
                    self.tableView.reloadData()
                }
            }
        })
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return cellDataList.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardsListTableViewCell", for: indexPath) as! BoardsListTableViewCell

        cell.boardLabel.text = cellDataList[indexPath.row].board?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.categoryLabel.text = cellDataList[indexPath.row].category?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.nameLabel.text = cellDataList[indexPath.row].name?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.moderatorLabel.text = cellDataList[indexPath.row].moderator?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        // Configure the cell...

        return cell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
