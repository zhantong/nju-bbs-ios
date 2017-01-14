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

class BoardViewController: UIViewController {
    var boardsListCellDataList = [BoardsListCellData]()
    var currentBoardLabel: BoardLabel!
    var labelArray: [BoardLabel] = []
    var currentArticleListTableViewController: ArticleListTableViewController? = nil
    let baseUrl = "http://bbs.nju.edu.cn"
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

    @IBOutlet weak var contentScrollView: UIScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
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
                    self.initContentScrollView()
                    self.initFirstBoard()
                })
    }

    func initContentScrollView() {
        contentScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width * CGFloat(labelArray.count), height: 0)
        contentScrollView.isPagingEnabled = true
        contentScrollView.delegate = self
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
        let index = labelArray.index(of: label)

        currentBoardLabel.scale = 0
        label.scale = 1
        //currentBoardLabel = label

        let offsetX = CGFloat(index!) * contentScrollView.bounds.width
        let offset = CGPoint(x: offsetX, y: 0)
        contentScrollView.setContentOffset(offset, animated: false)
        scrollViewDidEndScrollingAnimation(contentScrollView)
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
        let index = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        self.currentBoardLabel = self.labelArray[index]
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
        let articleListTableViewController = storyboard?.instantiateViewController(withIdentifier: "ArticleListTableViewController") as! ArticleListTableViewController
        articleListTableViewController.boardType = currentBoardLabel.type
        articleListTableViewController.boardUrl = currentBoardLabel.url
        self.addChildViewController(articleListTableViewController)
        contentScrollView.addSubview(articleListTableViewController.tableView)
        articleListTableViewController.didMove(toParentViewController: self)

        if currentArticleListTableViewController != nil {
            currentArticleListTableViewController?.willMove(toParentViewController: nil)
            currentArticleListTableViewController?.tableView.removeFromSuperview()
            currentArticleListTableViewController?.removeFromParentViewController()
        }
        currentArticleListTableViewController = articleListTableViewController
        articleListTableViewController.tableView.frame = contentScrollView.bounds
    }

}
