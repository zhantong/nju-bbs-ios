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
import CoreData

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
    var needReload = false
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

    @IBAction func edit(_ sender: UIButton) {
        needReload = true
        performSegue(withIdentifier: "editPreferred", sender: sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        initBoardsListScrollView()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        if needReload {
            initBoardsListScrollView()
            needReload = false
        }
    }

    func initBoardsListScrollView() {
        for label in labelArray {
            label.removeFromSuperview()
        }
        labelArray.removeAll()
        boardsListCellDataList.removeAll()
        let label = BoardLabel()
        label.type = 1
        label.text = "全站十大"
        label.textColor = UIColor.black
        label.sizeToFit()
        label.frame.origin.x = self.labelX(self.labelArray)
        label.frame.origin.y = (self.boardsListScroll.bounds.height - label.bounds.height) * 0.5
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BoardViewController.boardLabelClick(recognizer:))))
        label.isUserInteractionEnabled = true
        labelArray.append(label)
        boardsListScroll.addSubview(label)
        getBoards()
        for boardsListCellData in self.boardsListCellDataList {
            let label = BoardLabel()
            label.type = 2
            label.url = boardsListCellData.boardUrl
            label.text = boardsListCellData.name
            label.textColor = UIColor.black
            label.sizeToFit()
            label.frame.origin.x = self.labelX(self.labelArray)
            label.frame.origin.y = (self.boardsListScroll.bounds.height - label.bounds.height) * 0.5
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BoardViewController.boardLabelClick(recognizer:))))
            label.isUserInteractionEnabled = true
            self.labelArray.append(label)
            self.boardsListScroll.addSubview(label)
        }
        self.boardsListScroll.contentSize = CGSize(width: self.labelX(self.labelArray), height: 0)
        self.initContentScrollView()
        boardLabelClick(label: labelArray.first!)
    }

    func initContentScrollView() {
        contentScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width * CGFloat(labelArray.count), height: 0)
        contentScrollView.isPagingEnabled = true
        contentScrollView.delegate = self
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }

    func getBoards() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Board")
        let sortDescriptor = NSSortDescriptor(key: "index", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            let searchResult = try getContext().fetch(fetchRequest)
            for board in (searchResult as! [NSManagedObject]) {
                self.boardsListCellDataList.append(BoardsListCellData(board: board.value(forKey: "code") as! String!, category: board.value(forKey: "category") as! String!, name: board.value(forKey: "name") as! String!, moderator: board.value(forKey: "moderator") as! String!, boardUrl: board.value(forKey: "url") as! String!))
            }
        } catch {
            print(error)
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
    func boardLabelClick(recognizer: UITapGestureRecognizer) {

        let label = recognizer.view as! BoardLabel
        boardLabelClick(label: label)
    }

    func boardLabelClick(label: BoardLabel) {
        let index = labelArray.index(of: label)

        currentBoardLabel?.scale = 0
        label.scale = 1

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
