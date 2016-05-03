//
//  CategorysViewModel.swift
//  SwiftGGQing
//
//  Created by 宋宋 on 16/4/12.
//  Copyright © 2016年 org.dianqk. All rights reserved.
//

import RxSwift
import RxCocoa
import RealmSwift

final class CategorysViewModel {
	let elements = Variable<[CategoryObject]>([])

	let errorMessage = Variable<ErrorType?>(nil)

	let isRefreshing = Variable(true)

	private var realmNotificationToken: NotificationToken?

	private let disposeBag = DisposeBag()

	init(refreshTrigger: Driver<Void>) {
		if let realm = try? Realm() {
			realm.objects(CategoryObject.self)
                .asObservable()
				.map { $0.map { $0 } }
				.bindTo(elements)
				.addDisposableTo(disposeBag)
		}
        
        let updated = SyncService.sharedInstance.categoriesUpdated
            .filter { $0 }.map { _ in }

		let refreshResult = [refreshTrigger.asObservable(), updated].toObservable()
		// TODO: - 换一个合适的位置
		.merge()
			.flatMapLatest { GGProvider.request(GGAPI.CategoryList)
					.gg_storeArray(CategoryObject) }

        refreshResult.subscribe().addDisposableTo(disposeBag)
        
        
		[refreshTrigger.asObservable().map { _ in true }, refreshResult.map { _ in false }].toObservable()
            .merge()
            .bindTo(isRefreshing)
            .addDisposableTo(disposeBag)
	}
}
