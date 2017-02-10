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

class BoardsListTableViewController: UITableViewController {
    let baseUrl = "http://bbs.nju.edu.cn"
    var cellDataList = [BoardsListCellData]()
    var preferredCellDataList = [BoardsListCellData]()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refreshControl?.attributedTitle = NSAttributedString(string: "下拉刷新")

        getAllBoards()
        self.tableView.reloadData()
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension;

        isEditing = true
    }

    func refresh() {
        cellDataList.removeAll()
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
                                self.cellDataList.append(BoardsListCellData(board: code, category: category, name: name, moderator: moderator, boardUrl: url))
                                if !self.checkBoardCodeExists(code: code) {
                                    self.storeBoard(code: code, category: category, name: name, moderator: moderator, url: url!)
                                }
                            }
                            self.tableView.reloadData()
                            self.refreshControl?.endRefreshing()
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
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "喜欢"
        }
        return "列表"
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.section == 0 && destinationIndexPath.section == 1 {
            updatePreferred(code: preferredCellDataList[sourceIndexPath.row].board, preferred: false)
            cellDataList.insert(preferredCellDataList[sourceIndexPath.row], at: destinationIndexPath.row)
            preferredCellDataList.remove(at: sourceIndexPath.row)
        } else if sourceIndexPath.section == 1 && destinationIndexPath.section == 0 {
            updatePreferred(code: cellDataList[sourceIndexPath.row].board, preferred: true)
            preferredCellDataList.insert(cellDataList[sourceIndexPath.row], at: destinationIndexPath.row)
            cellDataList.remove(at: sourceIndexPath.row)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return preferredCellDataList.count
        } else {
            return cellDataList.count
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardsListTableViewCell", for: indexPath) as! BoardsListTableViewCell
        if indexPath.section == 0 {
            cell.boardLabel.text = preferredCellDataList[indexPath.row].board?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.categoryLabel.text = preferredCellDataList[indexPath.row].category?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.nameLabel.text = preferredCellDataList[indexPath.row].name?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.moderatorLabel.text = preferredCellDataList[indexPath.row].moderator?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else {
            cell.boardLabel.text = cellDataList[indexPath.row].board?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.categoryLabel.text = cellDataList[indexPath.row].category?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.nameLabel.text = cellDataList[indexPath.row].name?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.moderatorLabel.text = cellDataList[indexPath.row].moderator?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        // Configure the cell...

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellData = cellDataList[indexPath.row]
        print(cellData.boardUrl)
        self.performSegue(withIdentifier: "GoToBoard", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToBoard" {
            if let destination = segue.destination as? BoardTableViewController {
                let indexPath = tableView.indexPathForSelectedRow
                destination.viaSegue = baseUrl + "/" + cellDataList[(indexPath?.row)!].boardUrl
            }
        }
    }

    func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }

    func storeBoard(code: String, category: String, name: String, moderator: String, url: String) {
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "Board", in: context)
        let board = NSManagedObject(entity: entity!, insertInto: context)

        board.setValue(code, forKey: "code")
        board.setValue(category, forKey: "category")
        board.setValue(name, forKey: "name")
        board.setValue(moderator, forKey: "moderator")
        board.setValue(url, forKey: "url")

        do {
            try context.save()
            print("saved")
        } catch {
            print(error)
        }
    }

    func getAllBoards() {
        let fetchRequestPreferred = NSFetchRequest<NSFetchRequestResult>(entityName: "Board")
        fetchRequestPreferred.predicate = NSPredicate(format: "preferred == YES")
        let fetchRequestNormal = NSFetchRequest<NSFetchRequestResult>(entityName: "Board")
        fetchRequestNormal.predicate = NSPredicate(format: "preferred == NO")
        do {
            let searchResultPreferred = try getContext().fetch(fetchRequestPreferred)
            for board in (searchResultPreferred as! [NSManagedObject]) {
                self.preferredCellDataList.append(BoardsListCellData(board: board.value(forKey: "code") as! String!, category: board.value(forKey: "category") as! String!, name: board.value(forKey: "name") as! String!, moderator: board.value(forKey: "moderator") as! String!, boardUrl: board.value(forKey: "url") as! String!))
            }
            let searchResult = try getContext().fetch(fetchRequestNormal)
            for board in (searchResult as! [NSManagedObject]) {
                self.cellDataList.append(BoardsListCellData(board: board.value(forKey: "code") as! String!, category: board.value(forKey: "category") as! String!, name: board.value(forKey: "name") as! String!, moderator: board.value(forKey: "moderator") as! String!, boardUrl: board.value(forKey: "url") as! String!))
            }
        } catch {
            print(error)
        }
    }

    func deleteAllBoards() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Board")
        let context = getContext()
        do {
            let searchResult = try context.fetch(fetchRequest)
            for board in (searchResult as! [NSManagedObject]) {
                context.delete(board)
            }
        } catch {
            print(error)
        }
        do {
            try context.save()
            print("saved")
        } catch {
            print(error)
        }
    }

    func checkBoardCodeExists(code: String) -> Bool {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Board")
        fetchRequest.predicate = NSPredicate(format: "code == %@", code)
        let fetchResult = try! getContext().fetch(fetchRequest) as! [NSManagedObject]
        if fetchResult.count > 0 {
            return true
        }
        return false
    }

    func updatePreferred(code: String, preferred: Bool) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Board")
        fetchRequest.predicate = NSPredicate(format: "code == %@", code)
        let context = getContext()
        do {
            let searchResultPreferred = try context.fetch(fetchRequest)
            for board in (searchResultPreferred as! [NSManagedObject]) {
                board.setValue(preferred, forKey: "preferred")
            }
        } catch {
            print(error)
        }
        do {
            try context.save()
            print("saved")
        } catch {
            print(error)
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
