//
//  BoardTableViewController.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/12.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

struct BoardCellData {
    let status: String!
    let author: String!
    let time: String!
    let title: String!
    let numRead: String!
    let titleUrl: String!
}
extension String {
    mutating func stringByRepairTr() {
        do {
            let nsString = self as NSString
            let regex = try NSRegularExpression(pattern: "^<tr>.*?(?!</tr>)$", options: [NSRegularExpression.Options.caseInsensitive, NSRegularExpression.Options.anchorsMatchLines])
            let range = NSMakeRange(0, nsString.length)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$0</tr>")
        } catch {
            print("something wrong")
            return
        }
    }
    mutating func stringByRepairTd() {
        do {
            let nsString = self as NSString
            let regex = try NSRegularExpression(pattern: "(<td>.*?(?!</td>))(?=<td>|$)", options: [NSRegularExpression.Options.caseInsensitive, NSRegularExpression.Options.anchorsMatchLines])
            let range = NSMakeRange(0, nsString.length)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$0</td>")
        } catch {
            print("something wrong")
            return
        }
    }
}
class BoardTableViewController: UITableViewController {
    var viaSegue = ""
    var cellDataList = [BoardCellData]()
    override func viewDidLoad() {
        super.viewDidLoad()
        print(viaSegue)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        Alamofire.request(viaSegue).responseData(completionHandler: {
            response in
            print(response.request!)
            print(response.response!)
            print(response.data!)
            if let data = response.result.value, var content = String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) {
                content.stringByRepairTd()
                content.stringByRepairTr()
                print(content)
                if let doc = HTML(html: content, encoding: .utf8) {
                    for row in doc.xpath("//table[last()]/tr[position()>1]") {
                        print(row.text)
                        let status = row.at_xpath("./td[2]")
                        let author = row.at_xpath("./td[3]")
                        print(author?.text)
                        let time = row.at_xpath("./td[5]")
                        print(time?.text)
                        let title = row.at_xpath("./td[6]")
                        print("title: " + (title?.text)!)
                        let numRead = row.at_xpath("./td[7]")
                        print(numRead?.text)
                        let titleUrl = title?.at_xpath("./a/@href")
                        self.cellDataList.append(BoardCellData(status: status?.text, author: author?.text, time: time?.text, title: title?.text, numRead: numRead?.text, titleUrl: titleUrl?.text))
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardTableViewCell", for: indexPath) as! BoardTableViewCell

        cell.statusLabel.text = cellDataList[indexPath.row].status?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.authorLabel.text = cellDataList[indexPath.row].author?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.timeLabel.text = cellDataList[indexPath.row].time?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.titleLabel.text = cellDataList[indexPath.row].title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.numReadLabel.text = cellDataList[indexPath.row].numRead?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

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
