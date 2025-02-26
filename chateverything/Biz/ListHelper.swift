import Foundation

struct ListHelperParams {
	var page: Int
	var pageSize: Int
	var sorts: [String: String]
	
	init(page: Int = 1, pageSize: Int = 20, sorts: [String: String] = [:]) {
		self.page = page
		self.pageSize = pageSize
		self.sorts = sorts
	}
}
class ListHelperEvents<T> {
	let onLoaded: (ListHelperParams, [T]) -> Void
	let onLoading: (ListHelperParams) -> Void
	let onError: (ListHelperParams, Error) -> Void

	init(onLoaded: @escaping (ListHelperParams, [T]) -> Void, onLoading: @escaping (ListHelperParams) -> Void, onError: @escaping (ListHelperParams, Error) -> Void) {
		self.onLoaded = onLoaded
		self.onLoading = onLoading
		self.onError = onError
	}
}
class ListHelper<T>: ObservableObject {
	@Published var list: [T] = []
	@Published var initial: Bool = false
	@Published var loading: Bool = false
	@Published var hasMore: Bool = true
	@Published var error: Error? = nil
	@Published var params: ListHelperParams = ListHelperParams()

	let events: ListHelperEvents<T>?
	let service: (ListHelperParams, Config) -> [T]

	init(service: @escaping (ListHelperParams, Config) -> [T], events: ListHelperEvents<T>? = nil) {
		self.service = service
		self.events = events
	}

	func setParams(params: ListHelperParams) {
		self.params = params
	}

	func load(config: Config) -> [T] {
		if self.loading {
			return []
		}
		self.loading = true
		self.list = self.service(self.params, config)
		self.loading = false

		return self.list
	}
	func loadMore(config: Config) -> [T] {
		if !self.hasMore {
			return []
		}
		if self.loading {
			return []
		}
		self.params.page += 1
		self.loading = true
		let list = self.service(self.params, config)
		self.list.append(contentsOf: list)
		self.loading = false
		if list.count < self.params.pageSize {
			self.hasMore = false
		}

		return list
	}
	func next(config: Config) -> [T] {
		self.params.page += 1
		self.loading = true
		self.list = self.service(self.params, config)
		self.loading = false

		return self.list
	}
}

