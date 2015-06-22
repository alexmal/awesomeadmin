@db.init ['image', 'category', 'color', 'extension', 'option', 'order', 'order_item', 'product', 'size', 'status', 'user', 'texture']
menu.admin = ->
	[
		menu.model 'category', 'Категории'
		menu.model 'product', 'Товары'
		menu.index 'extension', 'Статусы товаров', 'icon-new'
		menu.index 'order', 'Заказы', 'icon-cart4'
		menu.index 'status', 'Статусы заказов', 'icon-new'
		menu.model 'user', 'Пользователи', 'icon-users'
	]
menu.manager = ->
	[
		menu.index 'extension', 'Статусы товаров', 'icon-new'
		menu.index 'order', 'Заказы', 'icon-cart4'
		menu.index 'status', 'Статусы заказов', 'icon-new'
	]