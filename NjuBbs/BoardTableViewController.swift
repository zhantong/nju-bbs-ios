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
import CoreData


class BoardTableViewController: UITableViewController {
    var cellDataList = [BoardsListCellData]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        navigationItem.rightBarButtonItem = editButtonItem


        getBoards()
        self.tableView.reloadData()
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension;
    }

    override func viewWillAppear(_ animated: Bool) {
        print(cellDataList)
        self.tableView.reloadData()
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

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        navigationItem.setHidesBackButton(editing, animated: true)
        self.tableView.reloadSections([1], with: .automatic)
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let removed = cellDataList[sourceIndexPath.row]
        cellDataList.remove(at: sourceIndexPath.row)
        cellDataList.insert(removed, at: destinationIndexPath.row)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return cellDataList.count
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("deleted")
            self.cellDataList.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BoardsListTableViewCell", for: indexPath) as! BoardsListTableViewCell

            cell.boardLabel.text = cellDataList[indexPath.row].board?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.categoryLabel.text = cellDataList[indexPath.row].category?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.nameLabel.text = cellDataList[indexPath.row].name?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.moderatorLabel.text = cellDataList[indexPath.row].moderator?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NormalTableViewCell", for: indexPath) as! NormalTableViewCell
            cell.nameLabel.text = "添加新的版面"
            if isEditing {
                cell.isHidden = true
            }
            return cell
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deleteAllBoards()
        for (index, item) in cellDataList.enumerated() {
            storeBoard(code: item.board, category: item.category, name: item.name, moderator: item.moderator, url: item.boardUrl, index: index)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            performSegue(withIdentifier: "ShowBoardsList", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowBoardsList" {
            if let destination = segue.destination as? BoardsListTableViewController {
                destination.exceptions = cellDataList
                destination.previousViewController = self
            }
        }
    }

    func appendBoard(board: BoardsListCellData) {
        cellDataList.append(board)
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
                self.cellDataList.append(BoardsListCellData(board: board.value(forKey: "code") as! String!, category: board.value(forKey: "category") as! String!, name: board.value(forKey: "name") as! String!, moderator: board.value(forKey: "moderator") as! String!, boardUrl: board.value(forKey: "url") as! String!))
            }
        } catch {
            print(error)
        }
    }

    func storeBoard(code: String, category: String, name: String, moderator: String, url: String, index: Int) {
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "Board", in: context)
        let board = NSManagedObject(entity: entity!, insertInto: context)

        board.setValue(code, forKey: "code")
        board.setValue(category, forKey: "category")
        board.setValue(name, forKey: "name")
        board.setValue(moderator, forKey: "moderator")
        board.setValue(url, forKey: "url")
        board.setValue(index, forKey: "index")

        do {
            try context.save()
            print("saved")
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
