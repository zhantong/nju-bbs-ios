//
//  ArticleCell.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/15.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import AsyncDisplayKit

class ArticleCell: ASCellNode {
    let authorNode = ASTextNode()
    let timeNode = ASTextNode()
    var contentNodes = [ASDisplayNode]()
    override init() {
        super.init()
        addSubnode(authorNode)
        addSubnode(timeNode)
    }

    func countChar(_ str: String) -> Int {
        var count = 0
        for char in str.unicodeScalars {
            if char.isASCII {
                count += 1
            } else {
                count += 2
            }
        }
        return count
    }

    func configureData(content: String, author: String, time: String) {
        authorNode.attributedText = NSAttributedString(string: author)
        timeNode.attributedText = NSAttributedString(string: time)

        let template = "\u{16E5}"
        let components = content.replacingOccurrences(of: "(?=http\\S{0,100}(gif|jpg|png|jpeg))|(?<=http\\S{0,100}(gif|jpg|png|jpeg))", with: template, options: .regularExpression).components(separatedBy: template)
        for component in components {
            if component.range(of: "http\\S{0,100}(gif|jpg|png|jpeg)", options: .regularExpression) != nil {
                let imageNode = ASNetworkImageNode()
                imageNode.url = URL(string: component)
                addSubnode(imageNode)
                contentNodes.append(imageNode)
            } else {
                var newComponent = ""
                component.enumerateLines(invoking: {
                    (line, _) in
                    newComponent.append(line)
                    print(self.countChar(line), line)
                    if self.countChar(line) < 76 {
                        newComponent.append("\n")
                    }
                })
                let textNode = ASTextNode()
                addSubnode(textNode)
                textNode.attributedText = NSAttributedString(string: newComponent)
                contentNodes.append(textNode)
            }
        }
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let authorInset = ASInsetLayoutSpec(insets: UIEdgeInsetsMake(0, 10, 0, 10), child: authorNode)
        let timeInset = ASInsetLayoutSpec(insets: UIEdgeInsetsMake(0, 10, 0, 10), child: timeNode)
        let verticalStack = ASStackLayoutSpec()
        var children = [ASLayoutElement]()
        verticalStack.direction = ASStackLayoutDirection.vertical
        children.append(authorInset)
        for node in contentNodes {
            let inset = ASInsetLayoutSpec(insets: UIEdgeInsetsMake(0, 10, 0, 10), child: node)
            children.append(inset)
        }
        let testInset = ASInsetLayoutSpec(insets: UIEdgeInsetsMake(0, 10, 0, 10), child: contentNodes[0])
        children.append(timeInset)
        verticalStack.children = children
        return verticalStack
    }
}
