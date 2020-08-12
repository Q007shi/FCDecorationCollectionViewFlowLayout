//
//  FCDecorationCollectionViewFlowLayout.swift
//  FCDecorationCollectionViewFlowLayout
//
//  Created by 石富才 on 2020/8/12.
//

import UIKit

class FCDecorationCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    private var decorationArr: [Int : [UICollectionViewLayoutAttributes]] = [:]
    public weak var decorationViewDelegate: FCDecorationCollectionViewFlowLayoutDelegate?
    
    override func prepare() {
        super.prepare()
        
        //获取组数
        guard let sectionNum = self.collectionView?.numberOfSections else { return }

        let flowLayoutDelegate: UICollectionViewDelegateFlowLayout? = self.collectionView?.delegate as? UICollectionViewDelegateFlowLayout
        
        //是否为 DecorationView 设置了代理
        guard let tempDecorationViewDelegate = decorationViewDelegate else { return }
        
        //删除旧的 DecorationView 布局数据
        decorationArr.removeAll()
        
        //获取每个 section 的 DecorationView 的 frame
        for section in 0 ..< sectionNum {
            //获取 section 中第一个和最后一个 item 的布局信息
            
            let decorationViewMsgs = tempDecorationViewDelegate.collectionView(self.collectionView!, layout: self, decorationMsgForSection: section)
            guard let tempDecorationViewMsgs = decorationViewMsgs,tempDecorationViewMsgs.count > 0 else{
                continue
            }
            
            guard let itemNum = self.collectionView?.numberOfItems(inSection: section),itemNum > 0,let firstItem = self.layoutAttributesForItem(at: IndexPath(item: 0, section: section)),let lastItem = self.layoutAttributesForItem(at: IndexPath(item: itemNum - 1, section: section)) else {
                continue
            }
            //获取当前 section 的边距
            var sectionInset = self.sectionInset
            if let inset = flowLayoutDelegate?.collectionView?(self.collectionView!, layout: self, insetForSectionAt: section) {
                sectionInset = inset
            }
            
            //计算 DecorationView 的 frame
            var sectionFrame = firstItem.frame.union(lastItem.frame)//frame 求并集
            if scrollDirection == .horizontal {
                sectionFrame.origin.x -= sectionInset.left
                sectionFrame.size.width += sectionInset.left + sectionInset.right
                
                sectionFrame.origin.y = sectionInset.top
                sectionFrame.size.height = self.collectionView!.frame.size.height - sectionInset.top - sectionInset.bottom
            }else {
                sectionFrame.origin.x = sectionInset.left
                sectionFrame.size.width = self.collectionView!.frame.size.width - sectionInset.left - sectionInset.right
                
                sectionFrame.origin.y -= sectionInset.top
                sectionFrame.size.height += sectionInset.top
            }
            
            var decorationViewAttris: [UICollectionViewLayoutAttributes] = []
            for decorationMsg in tempDecorationViewMsgs {
                guard let layoutAttri = decorationMsg.decorationViewAttributes else { continue }
                layoutAttri.frame = sectionFrame
                if let edgeInset = decorationMsg.decorationViewEdgeInsets {
                    layoutAttri.frame.origin.x -= edgeInset.left
                    layoutAttri.frame.size.width += edgeInset.left + edgeInset.right
                    
                    layoutAttri.frame.origin.y -= edgeInset.top
                    layoutAttri.frame.size.height += edgeInset.top + edgeInset.bottom
                }
                if let size = decorationMsg.decorationViewSize {
                    layoutAttri.frame.size = size
                }
                decorationViewAttris.append(layoutAttri)
            }
            decorationArr[section] = decorationViewAttris
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attris = super.layoutAttributesForElements(in: rect)
        for decorationViewAttris in decorationArr.values {
            for attri in decorationViewAttris {
                if rect.intersects(attri.frame) {
                    attris?.append(attri)
                }
            }
        }
        return attris
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        //是否为 DecorationView 设置了代理
        guard let tempDecorationViewDelegate = decorationViewDelegate else {
            return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)
        }
        
        let decorationViewMsgs = tempDecorationViewDelegate.collectionView(self.collectionView!, layout: self, decorationMsgForSection: indexPath.section)
        guard let tempDecorationViewMsgs = decorationViewMsgs else {
            return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)
        }
        for decorationViewMsg in tempDecorationViewMsgs {
            if elementKind == NSStringFromClass(type(of: decorationViewMsg.decorationView)) {
                return decorationViewMsg.decorationViewAttributes
            }
        }
        return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)
    }
}

class FCDecorationMsgModel: NSObject{
    
    var decorationView: UICollectionReusableView!
    //zIndex用于设置front-to-back层级；值越大，优先布局在上层；cell的zIndex为0
    var decorationViewAttributes: UICollectionViewLayoutAttributes!
    
    //这两个属性决定 decorationViewAttributes 的 frame
    var decorationViewEdgeInsets: UIEdgeInsets?
    var decorationViewSize: CGSize?
}

protocol FCDecorationCollectionViewFlowLayoutDelegate: NSObjectProtocol {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: FCDecorationCollectionViewFlowLayout, decorationMsgForSection section: Int) -> [FCDecorationMsgModel]?;
}
extension FCDecorationCollectionViewFlowLayoutDelegate{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: FCDecorationCollectionViewFlowLayout, decorationMsgForSection section: Int) -> [FCDecorationMsgModel]?{
        return nil
    }
}
