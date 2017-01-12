//
//  TopTenTableViewController.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/11.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

struct CellData {
    let title: String!
    let author: String!
    let board: String!
    let numReply: String!
    let titleUrl: String!
}
class TopTenTableViewController: UITableViewController {
    let baseUrl = "http://bbs.nju.edu.cn"
    var cellDataList = [CellData]()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        Alamofire.request(baseUrl + "/bbstop10").responseData(completionHandler: {
            response in
            print(response.request!)
            print(response.response!)
            print(response.data!)
            if let data = response.result.value, let content = String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) {
                if let doc = HTML(html: content, encoding: .utf8) {
                    for row in doc.xpath("//table/tr[position()>1]") {
                        print(row.text)
                        let board = row.at_xpath("./td[2]")
                        let title = row.at_xpath("./td[3]")
                        let author = row.at_xpath("./td[4]")
                        let numReply = row.at_xpath("./td[5]")
                        let titleUrl = title?.at_xpath("./a/@href")
                        self.cellDataList.append(CellData(title: title?.text, author: author?.text, board: board?.text, numReply: numReply?.text, titleUrl: titleUrl?.text))
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


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellDataList.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TopTenTableViewCell", for: indexPath) as! TopTenTableViewCell

        cell.authorLabel.text = cellDataList[indexPath.row].author?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.titleLabel.text = cellDataList[indexPath.row].title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.boardLabel.text = cellDataList[indexPath.row].board?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.numReplyLabel.text = cellDataList[indexPath.row].numReply?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellData = cellDataList[indexPath.row]
        print(cellData.titleUrl)
        self.performSegue(withIdentifier: "GoToArticle", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToArticle" {
            if let destination = segue.destination as? ArticleTableViewController {
                let indexPath = tableView.indexPathForSelectedRow
                destination.viaSegue = baseUrl + "/" + cellDataList[(indexPath?.row)!].titleUrl
            }
        }
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
