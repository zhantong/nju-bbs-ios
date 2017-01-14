//
//  ArticleListTableViewController.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/14.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

class ArticleListTableViewController: UITableViewController {
    struct TopTenCellData {
        let title: String!
        let author: String!
        let board: String!
        let numReply: String!
        let titleUrl: String!
    }
    struct BoardCellData {
        let status: String!
        let author: String!
        let time: String!
        let title: String!
        let numRead: String!
        let titleUrl: String!
    }
    var boardType: Int = 0
    var boardUrl: String = ""
    let baseUrl = "http://bbs.nju.edu.cn"
    var topTenCellDataList = [TopTenCellData]()
    var boardCellDataList = [BoardCellData]()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        if boardType == 1 {
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
                            self.topTenCellDataList.append(TopTenCellData(title: title?.text, author: author?.text, board: board?.text, numReply: numReply?.text, titleUrl: titleUrl?.text))
                        }
                        self.tableView.reloadData()
                    }
                }
            })
        } else if boardType == 2 {
            Alamofire.request(baseUrl + "/" + boardUrl).responseData(completionHandler: {
                response in
                print(response.request!)
                print(response.response!)
                print(response.data!)
                if let data = response.result.value, var content = String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) {
                    content.stringByRepairTd()
                    content.stringByRepairTr()
                    print(content)
                    if let doc = HTML(html: content, encoding: .utf8) {
                        let tableHead = doc.at_xpath("//table[last()]/tr[1]")
                        var columnIndexStatus = 0, columnIndexAuthor = 0, columnIndexTime = 0, columnIndexTitle = 0, columnIndexNumRead = 0
                        for (index, headItem) in (tableHead?.xpath("./td").enumerated())! {
                            if let item = headItem.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                                switch item {
                                case "状态":
                                    columnIndexStatus = index + 1
                                case "作者":
                                    columnIndexAuthor = index + 1
                                case "日期":
                                    columnIndexTime = index + 1
                                case "标题":
                                    columnIndexTitle = index + 1
                                case "回帖/人气":
                                    columnIndexNumRead = index + 1
                                default:
                                    ""
                                }
                            }
                        }
                        for row in doc.xpath("//table[last()]/tr[position()>1]") {
                            let status = row.at_xpath("./td[\(columnIndexStatus)]")
                            let author = row.at_xpath("./td[\(columnIndexAuthor)]")
                            print(author?.text)
                            let time = row.at_xpath("./td[\(columnIndexTime)]")
                            print(time?.text)
                            let title = row.at_xpath("./td[\(columnIndexTitle)]")
                            print("title: " + (title?.text)!)
                            let numRead = row.at_xpath("./td[\(columnIndexNumRead)]")
                            print(numRead?.text)
                            let titleUrl = title?.at_xpath("./a/@href")
                            print(titleUrl?.text)
                            self.boardCellDataList.append(BoardCellData(status: status?.text, author: author?.text, time: time?.text, title: title?.text, numRead: numRead?.text, titleUrl: titleUrl?.text))
                        }
                        self.tableView.reloadData()
                    }
                }
            })
        }
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
        if boardType == 1 {
            return topTenCellDataList.count
        } else if boardType == 2 {
            return boardCellDataList.count
        }
        return 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if boardType == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopTenTableViewCell", for: indexPath) as! TopTenTableViewCell

            cell.authorLabel.text = topTenCellDataList[indexPath.row].author?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.titleLabel.text = topTenCellDataList[indexPath.row].title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.boardLabel.text = topTenCellDataList[indexPath.row].board?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.numReplyLabel.text = topTenCellDataList[indexPath.row].numReply?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            return cell
        } else if boardType == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BoardTableViewCell", for: indexPath) as! BoardTableViewCell

            cell.statusLabel.text = boardCellDataList[indexPath.row].status?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.authorLabel.text = boardCellDataList[indexPath.row].author?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.timeLabel.text = boardCellDataList[indexPath.row].time?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.titleLabel.text = boardCellDataList[indexPath.row].title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.numReadLabel.text = boardCellDataList[indexPath.row].numRead?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            return cell
        }
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "GoToArticle", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToArticle" {
            if let destination = segue.destination as? ArticleTableViewController {
                let indexPath = tableView.indexPathForSelectedRow
                if boardType == 1 {
                    destination.viaSegue = baseUrl + "/" + topTenCellDataList[(indexPath?.row)!].titleUrl
                } else if boardType == 2 {
                    destination.viaSegue = baseUrl + "/" + boardCellDataList[(indexPath?.row)!].titleUrl
                }

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
