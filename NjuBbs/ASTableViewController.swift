//
//  ASTableViewController.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/15.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import Alamofire
import Darwin.POSIX.iconv
import MJRefresh

extension String {
    mutating func stringByRemovingUnsupportedColor() {
        do {
            let regex = try NSRegularExpression(pattern: "\\033\\[.*?m", options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.characters.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        } catch {
            return
        }
    }
}

class ASTableViewController: ASViewController<ASTableNode>, ASTableDataSource, ASTableDelegate {

    struct ArticleCellData {
        let content: String!
        let author: String!
        let time: String!
    }

    var viaSegue = ""
    var cellDataList = [ArticleCellData]()
    var moreArticlesUrl = ""
    var pullUpLoadMoreLocked = false
    let baseUrl = "http://bbs.nju.edu.cn"
    let footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(ASTableViewController.footerRefresh))
    func requestArticles(url: String, dataHandler: @escaping ([ArticleCellData], String) -> Void) {
        Alamofire.request(url).responseData(completionHandler: {
                    response in
                    print("url:", url)
                    print(response.request!)
                    print(response.response!)
                    print(response.data!)
                    print(response.result.value.debugDescription)
                    var articleCellDataList = [ArticleCellData]()
                    var moreArticlesUrl = ""
                    if let data = response.result.value {
                        let nsData = data as NSData
                        var content = try! IconV.convertCString(cstr: nsData.bytes.assumingMemoryBound(to: Int8.self), length: nsData.length, fromEncodingNamed: "GBK//IGNORE")
                        content.stringByRemovingUnsupportedColor()
                        print("preparing content")
                        let contentNsString = content as NSString
                        let nextPageUrlReg = try! NSRegularExpression(pattern: "<a\\s*href=(.*?)>本主题下30篇</a>", options: NSRegularExpression.Options.caseInsensitive)
                        let match = nextPageUrlReg.firstMatch(in: content, options: [], range: NSRange(location: 0, length: contentNsString.length))
                        if match != nil {
                            moreArticlesUrl = contentNsString.substring(with: match!.rangeAt(1))
                        }



                        let tablesReg = try! NSRegularExpression(pattern: "<table.*?>(.*?)</table>", options: NSRegularExpression.Options.dotMatchesLineSeparators)
                        let matches = tablesReg.matches(in: content, options: [], range: NSRange(location: 0, length: contentNsString.length))
                        print("table matches: ", matches)
                        for match in matches {
                            let tableContent = contentNsString.substring(with: match.rangeAt(1))
                            print("table content: " + tableContent)
                            let textareaReg = try! NSRegularExpression(pattern: "<textarea.*?>(.*?)</textarea>", options: NSRegularExpression.Options.dotMatchesLineSeparators)
                            let tableContentNsString = tableContent as NSString
                            let match = textareaReg.firstMatch(in: tableContent, options: [], range: NSRange(location: 0, length: tableContentNsString.length))
                            if match != nil {
                                let textareaContent = tableContentNsString.substring(with: match!.rangeAt(1))
                                let articleReg = try! NSRegularExpression(pattern: "发信人:\\s*(.*?),.*?发信站.*?\\((.*?)\\)(.*)--\\n※", options: NSRegularExpression.Options.dotMatchesLineSeparators)
                                let textareaContentNsString = textareaContent as NSString
                                let match = articleReg.firstMatch(in: textareaContent, options: [], range: NSRange(location: 0, length: textareaContentNsString.length))
                                if match != nil {
                                    let author = textareaContentNsString.substring(with: match!.rangeAt(1)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                    var time = textareaContentNsString.substring(with: match!.rangeAt(2)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                    var content = textareaContentNsString.substring(with: match!.rangeAt(3)).trimmingCharacters(in: CharacterSet.newlines)

                                    //let regexFakeNewLines=try!NSRegularExpression(pattern:"(?<=\r?\n|^)([^\n\r]{38,80})\r?\n+", options: .dotMatchesLineSeparators)
                                    //content=regexFakeNewLines.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, (content as NSString).length), withTemplate: "$1")

                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "E MMM d HH:mm:ss yyyy"
                                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                                    let dateTimeDate = dateFormatter.date(from: time) ?? Date()
                                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                                    time = dateFormatter.string(from: dateTimeDate)
                                    print("author: " + author)
                                    articleCellDataList.append(ArticleCellData(content: content, author: author, time: time))
                                }
                            }
                        }
                    }
                    dataHandler(articleCellDataList, moreArticlesUrl)
                })
    }

    func test(inData: UnsafePointer<Int8>?, length: Int) {
        let fromEncode = "GBK"
        let toEncode = "UTF-8"
        let intIconv = iconv_open(fromEncode, toEncode)
        print("iconv status: ", intIconv)
        var cStrPtr = UnsafeMutablePointer<Int8>(mutating: inData)
        var newPtr: UnsafeMutablePointer<Int8>? = nil
        var max = Int.max
        var tempLength = length
        iconv(intIconv, &cStrPtr, &tempLength, &newPtr, &max)
        print("out", String.init(cString: newPtr!))
        iconv_close(intIconv)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print(viaSegue)
        requestArticles(url: viaSegue, dataHandler: {
            data, moreArticlesUrl in
            self.cellDataList = data
            self.moreArticlesUrl = moreArticlesUrl
            print(self.moreArticlesUrl)
            self.tableNode.reloadData()
        })
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        footer?.setTitle("没有更多", for: .noMoreData)
        footer?.setTitle("正在加载", for: .refreshing)
        tableNode.view.mj_footer = footer
    }

    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        if moreArticlesUrl.isEmpty {
            footer?.endRefreshingWithNoMoreData()
            return false
        }
        return true
    }

    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        if !moreArticlesUrl.isEmpty {
            let url = baseUrl + "/" + moreArticlesUrl
            requestArticles(url: url, dataHandler: {
                data, moreArticlesUrl in
                self.cellDataList += data[1 ..< data.endIndex]
                self.moreArticlesUrl = moreArticlesUrl
                var indexPaths = [IndexPath]()
                for row in self.cellDataList.endIndex - data.endIndex + 1 ..< self.cellDataList.endIndex {
                    let path = IndexPath(row: row, section: 0)
                    indexPaths.append(path)
                }
                tableNode.insertRows(at: indexPaths, with: .automatic)
                context.completeBatchFetching(true)
            })
        }
    }

    func footerRefresh() {

    }
    var tableNode: ASTableNode {
        return node as! ASTableNode
    }
    init() {
        super.init(node: ASTableNode())
        tableNode.delegate = self
        tableNode.dataSource = self
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }

    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let node = ArticleCell()
        node.configureData(content: cellDataList[indexPath.row].content, author: cellDataList[indexPath.row].author, time: cellDataList[indexPath.row].time)
        return node
    }

    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 1
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return cellDataList.count
    }

}
