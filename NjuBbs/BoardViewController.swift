//
//  BoardViewController.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/13.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import UIKit
import Alamofire
import Kanna
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
class BoardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
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

    var boardsListCellDataList = [BoardsListCellData]()
    var currentBoardLabel: BoardLabel!
    var labelArray: [BoardLabel] = []
    let realSelf = self
    let labelX: ([UILabel]) -> CGFloat = {
        (labels: [UILabel]) -> CGFloat in

        let lastObj = labels.last
        guard let label = lastObj else {
            return 25
        }
        return label.frame.maxX + 25
    }
    @IBOutlet weak var boardsListScroll: UIScrollView!

    @IBOutlet weak var contentTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false

        contentTableView.delegate = self
        contentTableView.dataSource = self
        initBoardsListScrollView()
        // Do any additional setup after loading the view.
    }
    func initBoardsListScrollView() {
        let label = BoardLabel()
        label.type = 1
        label.text = "全站十大"
        label.textColor = UIColor.black
        label.sizeToFit()
        label.frame.origin.x = self.labelX(self.labelArray)
        label.frame.origin.y = (self.boardsListScroll.bounds.height - label.bounds.height) * 0.5
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BoardViewController.boardLabelClick(_:))))
        label.isUserInteractionEnabled = true
        labelArray.append(label)
        boardsListScroll.addSubview(label)
        Alamofire.request(baseUrl + "/bbsall").responseData(completionHandler: {
            response in
            print(response.request!)
            print(response.response!)
            print(response.data!)
            if let data = response.result.value, let content = String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) {
                if let doc = HTML(html: content, encoding: .utf8) {
                    for row in doc.xpath("//table/tr[position()>1]") {
                        let board = row.at_xpath("./td[2]")
                        let category = row.at_xpath("./td[3]")
                        let name = row.at_xpath("./td[4]")
                        let moderator = row.at_xpath("./td[5]")
                        let boardUrl = board?.at_xpath("./a/@href")
                        self.boardsListCellDataList.append(BoardsListCellData(board: board?.text, category: category?.text, name: name?.text, moderator: moderator?.text, boardUrl: boardUrl?.text?.replacingOccurrences(of: "bbsdoc", with: "bbstdoc")))
                    }
                }
            }
            for boardsListCellData in self.boardsListCellDataList {
                let label = BoardLabel()
                label.type = 2
                label.url = boardsListCellData.boardUrl
                label.text = boardsListCellData.name
                label.textColor = UIColor.black
                label.sizeToFit()
                label.frame.origin.x = self.labelX(self.labelArray)
                label.frame.origin.y = (self.boardsListScroll.bounds.height - label.bounds.height) * 0.5
                label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BoardViewController.boardLabelClick(_:))))
                label.isUserInteractionEnabled = true
                self.labelArray.append(label)
                self.boardsListScroll.addSubview(label)
            }
            self.boardsListScroll.contentSize = CGSize(width: self.labelX(self.labelArray), height: 0)
            self.initFirstBoard()
        })
    }
    func initFirstBoard() {
        let firstBoradLabel = labelArray.first!
        currentBoardLabel = firstBoradLabel
        firstBoradLabel.scale = 1
        scrollViewDidEndScrollingAnimation(self.boardsListScroll)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if boardType == 1 {
            return topTenCellDataList.count
        } else if boardType == 2 {
            return boardCellDataList.count
        }
        return 0
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "GoToArticle", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToArticle" {
            if let destination = segue.destination as? ArticleTableViewController {
                let indexPath = contentTableView.indexPathForSelectedRow
                if boardType == 1 {
                    destination.viaSegue = baseUrl + "/" + topTenCellDataList[(indexPath?.row)!].titleUrl
                } else if boardType == 2 {
                    destination.viaSegue = baseUrl + "/" + boardCellDataList[(indexPath?.row)!].titleUrl
                }

            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func boardLabelClick(_ recognizer: UITapGestureRecognizer) {

        let label = recognizer.view as! BoardLabel
        let index = label.tag

        currentBoardLabel.scale = 0
        label.scale = 1
        currentBoardLabel = label

        //let offsetX = CGFloat(index) * self.boardsListScroll.bounds.width
        //let offset = CGPoint(x: offsetX, y: 0)
        //这个方法animated为true才会导致scrollViewDidEndScrollingAnimation代理方法被调用
        //self.boardsListScroll.setContentOffset(offset, animated: false)
        //代码滚动到显示了那一"页"
        self.scrollViewDidEndScrollingAnimation(self.boardsListScroll)
    }

    func initTable() {
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
                        self.contentTableView.reloadData()
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
                        self.contentTableView.reloadData()
                    }
                }
            })
        }
        contentTableView.estimatedRowHeight = 150
        contentTableView.rowHeight = UITableViewAutomaticDimension;
    }
}
extension BoardViewController: UIScrollViewDelegate {

    /**
     每次滑动newsContainerView都会调用，用来制造频道label的动画效果
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let currentIndex = scrollView.contentOffset.x / scrollView.bounds.width
        let leftIndex = Int(currentIndex)
        let rightIndex = leftIndex + 1

        guard currentIndex > 0 && rightIndex < self.labelArray.count else {
            return
        }
        let rightScale = currentIndex - CGFloat(leftIndex)
        let leftScale = CGFloat(rightIndex) - currentIndex

        let rightLabel = self.labelArray[rightIndex]
        let leftLabel = self.labelArray[leftIndex]

        rightLabel.scale = rightScale
        leftLabel.scale = leftScale
    }

    /**
     这个是在newsContainerView减速停止的时候开始执行，
     用来切换需要显示的新闻列表和让频道标签处于合适的位置
     */
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.scrollViewDidEndScrollingAnimation(scrollView)
    }

    /**
     这个是当用户用代码导致滚动时候调用列如setContentOffset，
     用来切换需要显示的新闻列表和让频道标签处于合适的位置
     */
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        var offsetX = currentBoardLabel.center.x - self.boardsListScroll.bounds.width * 0.5
        let maxOffset = self.boardsListScroll.contentSize.width - self.boardsListScroll.bounds.width
        if offsetX > 0 {
            offsetX = offsetX > maxOffset ? maxOffset : offsetX
        } else {
            offsetX = 0
        }
        let offset = CGPoint(x: offsetX, y: 0)
        self.boardsListScroll.setContentOffset(offset, animated: true)

        // 切换需要显示的控制器
        boardType = currentBoardLabel.type
        boardUrl = currentBoardLabel.url
        topTenCellDataList.removeAll()
        boardCellDataList.removeAll()
        initTable()
        //let vc = self.newsListVcArray[index]
        //self.newsContainerView.showViewInScrollView(vc.tableView, showViewIndex: index)

    }

}
