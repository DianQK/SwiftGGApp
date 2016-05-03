//
//  CategoryViewController.swift
//  SwiftGGQing
//
//  Created by 宋宋 on 16/4/15.
//  Copyright © 2016年 org.dianqk. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import RxSwift
import RxCocoa
import RxDataSources
import NSObject_Rx
import RxOptional

private typealias CategoryList = AnimatableSectionModel<String, ArticleInfoObject>

final class CategoryViewController: UIViewController, SegueHandlerType {
    
	var category: CategoryObject!

	var viewModel: CategoryViewModel!

    enum SegueIdentifier: String {
        case ShowArticle
    }

	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var headerImageView: UIImageView!
    @IBOutlet private weak var indicatorView: UIActivityIndicatorView!

	override func viewDidLoad() {
		title = category.name
        
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let refresh = UIRefreshControl()
        tableView.addSubview(refresh)

        let refreshTrigger = refresh.rx_controlEvent(.ValueChanged).asObservable()
        
        let datasource = RxTableViewSectionedReloadDataSource<CategoryList>()
        datasource.configureCell = { ds, tb, ip, v in
            let cell = tb.dequeueReusableCellWithIdentifier(R.reuseIdentifier.articleTableViewCell, forIndexPath: ip)!
            cell.title = v.identity.title
            return cell
        }
        
		viewModel = CategoryViewModel(refreshTrigger: refreshTrigger, loadMoreTrigger: tableView.rx_reachedBottom, category: category)

		viewModel.elements.asDriver()
            .map { [CategoryList(model: "", items: $0)] }
            .drive(tableView.rx_itemsWithDataSource(datasource))
            .addDisposableTo(rx_disposeBag)
        
        viewModel.isLoading.asDriver()
            .drive(indicatorView.rx_animating)
            .addDisposableTo(rx_disposeBag)
        
        tableView.rx_modelSelected(IdentifiableValue<ArticleInfoObject>)
            .map { $0.identity }
            .subscribeNext(performSegueWithIdentifier(.ShowArticle))
            .addDisposableTo(rx_disposeBag)
        
	}
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segueIdentifierForSegue(segue) {
        case .ShowArticle:
            let articleManagerViewController = segue.destinationViewController.gg_castOrFatalError(ArticleManagerViewController.self)
            let articleInfo: ArticleInfoObject = castOrFatalError(sender)
            articleManagerViewController.articleInfo = articleInfo
        }
    }
}
