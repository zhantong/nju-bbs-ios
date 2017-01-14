//
//  ArticleTableViewController.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/11.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import UIKit
import Alamofire

struct ArticleCellData {
    let content: NSAttributedString!
    let author: String!
    let time: String!
}
extension String {
    var utf8Data: Data? {
        return data(using: .utf8)
    }
}
extension String {
    mutating func stringByRemovingRegexMatches() {
        do {
            let regex = try NSRegularExpression(pattern: "\\bhttp\\S*(gif|jpg|png|jpeg|jp)\\b", options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.characters.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "<img src='$0' />")
        } catch {
            return
        }
    }
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
class ArticleTableViewController: UITableViewController {
    var viaSegue = ""
    var cellDataList = [ArticleCellData]()
    override func viewDidLoad() {
        super.viewDidLoad()
        print(viaSegue)
        Alamofire.request(viaSegue).responseData(completionHandler: {
            response in
            print(response.request!)
            print(response.response!)
            print(response.data!)
            self.tableView.reloadData()
            if let data = response.result.value, var content = String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) {
                content.stringByRemovingRegexMatches()
                content.stringByRemovingUnsupportedColor()
                let tablesReg=try!NSRegularExpression(pattern: "<table.*?>(.*?)</table>", options: NSRegularExpression.Options.dotMatchesLineSeparators)
                let contentNsString=content as NSString
                let matches=tablesReg.matches(in: content, options: [], range: NSRange(location: 0, length: contentNsString.length))
                for match in matches{
                    let tableContent=contentNsString.substring(with: match.rangeAt(1))
                    let textareaReg=try!NSRegularExpression(pattern: "<textarea.*?>(.*?)</textarea>", options: NSRegularExpression.Options.dotMatchesLineSeparators)
                    let tableContentNsString=tableContent as NSString
                    let match=textareaReg.firstMatch(in: tableContent, options: [], range: NSRange(location: 0, length: tableContentNsString.length))
                    if match != nil{
                        let textareaContent=tableContentNsString.substring(with: match!.rangeAt(1))
                        let articleReg=try! NSRegularExpression(pattern: "发信人:\\s*(.*?),.*?发信站.*?\\((.*?)\\)(.*)--\\n※", options: NSRegularExpression.Options.dotMatchesLineSeparators)
                        let textareaContentNsString=textareaContent as NSString
                        let match=articleReg.firstMatch(in: textareaContent, options: [], range: NSRange(location: 0, length: textareaContentNsString.length))
                        if match != nil{
                            let author=textareaContentNsString.substring(with: match!.rangeAt(1)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            var time=textareaContentNsString.substring(with: match!.rangeAt(2)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            var content=textareaContentNsString.substring(with: match!.rangeAt(3)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                            let dateFormatter=DateFormatter()
                            dateFormatter.dateFormat = "E MMM d HH:mm:ss yyyy"
                            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                            let dateTimeDate=dateFormatter.date(from: time) ?? Date()
                            dateFormatter.dateFormat="yyyy-MM-dd HH:mm"
                            time=dateFormatter.string(from: dateTimeDate)

                            content = content.replacingOccurrences(of: "\n", with: "<br/>")
                            let attributedContent=try! NSAttributedString(data: content.data(using: .utf8)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
                            self.cellDataList.append(ArticleCellData(content: attributedContent, author: author, time: time))
                        }
                    }
                }
            }
                    self.tableView.reloadData()
        })
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleTableViewCell", for: indexPath) as! ArticleTableViewCell
        cell.contentLabel.attributedText = cellDataList[indexPath.row].content
        cell.authorLabel.text = cellDataList[indexPath.row].author
        cell.timeLabel.text = cellDataList[indexPath.row].time



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
