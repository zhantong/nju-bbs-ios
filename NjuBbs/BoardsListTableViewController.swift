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
import CoreData

struct BoardsListCellData {
    let board: String!
    let category: String!
    let name: String!
    let moderator: String!
    let boardUrl: String!
}

extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return substring(from: fromIndex)
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return substring(to: toIndex)
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return substring(with: startIndex ..< endIndex)
    }
}

class BoardsListTableViewController: UITableViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    let baseUrl = "http://bbs.nju.edu.cn"
    var cellDataList = [BoardsListCellData]()
    var searchResults = [BoardsListCellData]()
    var exceptions = [BoardsListCellData]()
    weak var previousViewController: BoardTableViewController?

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
                                let boardElement = row.at_xpath("./td[2]")
                                let categoryElement = row.at_xpath("./td[3]")
                                let nameElement = row.at_xpath("./td[4]")
                                let moderatorElement = row.at_xpath("./td[5]")
                                let boardUrlElement = boardElement?.at_xpath("./a/@href")

                                var code = boardElement!.text!
                                var category = categoryElement!.text!
                                category = category.substring(with: 1 ..< category.characters.count - 1)
                                var name = nameElement!.text!
                                name = name.substring(from: 2)
                                var moderator = moderatorElement!.text!
                                var url = boardUrlElement!.text?.replacingOccurrences(of: "bbsdoc", with: "bbstdoc")
                                if !self.checkBoardCodeExists(code: code) {
                                    self.cellDataList.append(BoardsListCellData(board: code, category: category, name: name, moderator: moderator, boardUrl: url))
                                }
                            }
                            self.searchResults = self.cellDataList
                            self.tableView.reloadData()
                            self.refreshControl?.endRefreshing()
                        }
                    }
                })
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension;

        self.tableView.reloadData()
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension;

        searchBar.delegate = self
        searchBar.placeholder = "搜索版面"
    }

    func checkBoardCodeExists(code: String) -> Bool {
        for board in exceptions {
            if code == board.board {
                return true
            }
        }
        return false
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
        return searchResults.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardsListTableViewCell", for: indexPath) as! BoardsListTableViewCell
        cell.boardLabel.text = searchResults[indexPath.row].board?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.categoryLabel.text = searchResults[indexPath.row].category?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.nameLabel.text = searchResults[indexPath.row].name?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.moderatorLabel.text = searchResults[indexPath.row].moderator?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        // Configure the cell...

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        previousViewController?.appendBoard(board: searchResults[indexPath.row])
        navigationController?.popViewController(animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults = cellDataList
        } else {
            searchResults = cellDataList.filter { cell in
                return cell.name.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchResults = cellDataList
        tableView.reloadData()
        searchBar.resignFirstResponder()
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
