//
//  CategoryViewModel.swift
//  SwiftGGQing
//
//  Created by 宋宋 on 16/4/15.
//  Copyright © 2016年 org.dianqk. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import Realm
import RealmSwift
import RxOptional

final class CategoryViewModel {

	let elements = Variable<[ArticleInfoObject]>([])
    
    let hasNextPage = Variable(true)
    
    let currentPage = Variable(1)

	let isLoading = Variable(true)
    
    let isRefreshing = Variable(true)

	private let disposeBag = DisposeBag()

	init(refreshTrigger: Observable<Void>, loadMoreTrigger: Observable<Void>, category: CategoryObject) {
        /// 事实上 == 这里不应该做 Cache
        let realm = try! Realm()
        let predicate = NSPredicate(format: "typeId == %@", argumentArray: [category.id])
        realm.objects(ArticleInfoObject).filter(predicate).asObservable()
            .subscribeNext { [unowned self] objects in
                self.elements.value = objects.map { $0 }
                self.isLoading.value = false
                self.currentPage.value = self.elements.value.count / GGConfig.Home.pageSize + 1
            }.addDisposableTo(disposeBag)
        
        let loadMoreRequest = loadMoreTrigger.withLatestFrom(currentPage.asObservable()).shareReplay(1)
        
        let loadMoreResult = loadMoreRequest
            .map { GGAPI.ArticlesByCategory(categoryId: category.id, pageIndex: $0, pageSize: GGConfig.Category.pageSize) }
            .flatMapLatest(GGProvider.request)
            // TODO: - 在这里加判断，是否需要更新 Model
            .gg_storeArray(ArticleInfoObject)
            .shareReplay(1)
        
        [loadMoreRequest.map { _ in true }, loadMoreResult.map { _ in false }]
            .toObservable()
            .merge()
            .bindTo(isLoading)
            .addDisposableTo(disposeBag)
	}
}
