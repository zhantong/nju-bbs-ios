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
    var pullUpLoadMoreLocked = false
    var isPullUpLoadMoreEnabled = false
    var moreArticlesUrl = ""
    func requestTopTen(dataHandler: @escaping ([TopTenCellData]) -> Void) {
        Alamofire.request(baseUrl + "/bbstop10").responseData(completionHandler: {
                    response in
                    var topTenCellDataList = [TopTenCellData]()
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
                                topTenCellDataList.append(TopTenCellData(title: title?.text, author: author?.text, board: board?.text, numReply: numReply?.text, titleUrl: titleUrl?.text))
                                //self.topTenCellDataList.append(TopTenCellData(title: title?.text, author: author?.text, board: board?.text, numReply: numReply?.text, titleUrl: titleUrl?.text))
                            }
                            //self.tableView.reloadData()
                        }
                    }
                    dataHandler(topTenCellDataList)
                })
    }

    func requestArticleList(url: String, dataHandler: @escaping ([BoardCellData], String) -> Void) {
        Alamofire.request(baseUrl + "/" + url).responseData(completionHandler: {
                    response in
                    print(response.request!)
                    print(response.response!)
                    print(response.data!)
                    var boardCellDataList = [BoardCellData]()
                    var moreArticlesUrl = ""
                    if let data = response.result.value, var content = String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) {
                        content.stringByRepairTd()
                        content.stringByRepairTr()
                        print(content)
                        if let doc = HTML(html: content, encoding: .utf8) {
                            let tableHead = doc.at_xpath("//table[last()]/tr[1]")
                            moreArticlesUrl = doc.at_xpath("//a[text()='上一页']/@href")?.text ?? ""
                            print("more articles url: ", self.moreArticlesUrl)
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
                                boardCellDataList.insert(BoardCellData(status: status?.text, author: author?.text, time: time?.text, title: title?.text, numRead: numRead?.text, titleUrl: titleUrl?.text), at: 0)
                            }
                        }
                    }
                    dataHandler(boardCellDataList, moreArticlesUrl)
                })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refreshControl?.attributedTitle = NSAttributedString(string: "下拉刷新")
        if boardType == 1 {
            isPullUpLoadMoreEnabled = false
        } else if boardType == 2 {
            isPullUpLoadMoreEnabled = true
        }
        if isPullUpLoadMoreEnabled {
            initPollUpLoadMore()
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        if boardType == 1 {
            requestTopTen(dataHandler: {
                data in
                self.topTenCellDataList = data
                self.tableView.reloadData()
            })
        } else if boardType == 2 {
            requestArticleList(url: boardUrl, dataHandler: {
                data, moreArticlesUrl in
                self.boardCellDataList += data
                self.moreArticlesUrl = moreArticlesUrl
                self.tableView.reloadData()
            })
        }
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension;
    }

    func refresh() {
        if boardType == 1 {
            requestTopTen(dataHandler: {
                data in
                self.topTenCellDataList.removeAll()
                self.topTenCellDataList = data
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            })
        } else if boardType == 2 {
            requestArticleList(url: boardUrl, dataHandler: {
                data, moreArticlesUrl in
                self.boardCellDataList.removeAll()
                self.boardCellDataList = data
                self.moreArticlesUrl = moreArticlesUrl
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            })
        }
    }

    func initPollUpLoadMore() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: 60))
        tableView.tableFooterView?.autoresizingMask = .flexibleWidth

        let activityViewIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityViewIndicator.color = .darkGray
        let indicatorX = (tableView.tableFooterView?.frame.size.width)! / 2 - activityViewIndicator.frame.width / 2
        let indicatorY = (tableView.tableFooterView?.frame.size.height)! / 2 - activityViewIndicator.frame.height / 2
        activityViewIndicator.frame = CGRect(x: indicatorX, y: indicatorY, width: activityViewIndicator.frame.width, height: activityViewIndicator.frame.height)
        activityViewIndicator.startAnimating()
        tableView.tableFooterView?.addSubview(activityViewIndicator)
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

            if isPullUpLoadMoreEnabled && !pullUpLoadMoreLocked && indexPath.row == topTenCellDataList.count - 1 {
                loadMore()
            }

            return cell
        } else if boardType == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BoardTableViewCell", for: indexPath) as! BoardTableViewCell

            cell.statusLabel.text = boardCellDataList[indexPath.row].status?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.authorLabel.text = boardCellDataList[indexPath.row].author?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.timeLabel.text = boardCellDataList[indexPath.row].time?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.titleLabel.text = boardCellDataList[indexPath.row].title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.numReadLabel.text = boardCellDataList[indexPath.row].numRead?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            if isPullUpLoadMoreEnabled && !pullUpLoadMoreLocked && indexPath.row == boardCellDataList.count - 1 {
                loadMore()
            }

            return cell
        }

        return UITableViewCell()
    }

    func loadMore() {
        pullUpLoadMoreLocked = true
        requestArticleList(url: moreArticlesUrl, dataHandler: {
            data, moreArticlesUrl in
            self.boardCellDataList += data
            self.moreArticlesUrl = moreArticlesUrl
            self.tableView.reloadData()
        })
        pullUpLoadMoreLocked = false
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
