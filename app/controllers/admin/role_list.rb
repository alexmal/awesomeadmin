Admin::RoleList = {
	admin: true,
	manager: {
		all: [
			'extension',
			'order',
			'order_item',
			'status'
		],
		get: [
			'product'
		]
	}
}