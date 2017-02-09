//
//  ArticleCell.swift
//  NjuBbs
//
//  Created by zhantong on 2017/1/15.
//  Copyright © 2017年 PolarXiong. All rights reserved.
//

import AsyncDisplayKit

class ArticleCell: ASCellNode {
    let contentNode = ASTextNode()
    let authorNode = ASTextNode()
    let timeNode = ASTextNode()
    override init() {
        super.init()
        addSubnode(contentNode)
        addSubnode(authorNode)
        addSubnode(timeNode)
    }

    func configureData(content: NSAttributedString, author: NSAttributedString, time: NSAttributedString) {
        contentNode.attributedText = content
        authorNode.attributedText = author
        timeNode.attributedText = time
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let authorInset = ASInsetLayoutSpec(insets: UIEdgeInsetsMake(0, 10, 0, 10), child: authorNode)
        let contentInset = ASInsetLayoutSpec(insets: UIEdgeInsetsMake(0, 10, 0, 10), child: contentNode)
        let timeInset = ASInsetLayoutSpec(insets: UIEdgeInsetsMake(0, 10, 0, 10), child: timeNode)
        let verticalStack = ASStackLayoutSpec()
        verticalStack.direction = ASStackLayoutDirection.vertical
        verticalStack.children = [authorInset, contentInset, timeInset]
        return verticalStack
    }
}
