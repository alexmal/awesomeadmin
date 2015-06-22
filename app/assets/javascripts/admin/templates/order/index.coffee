app.templates.index.order =
	order: 'created_at DESC'
	page: (recs) ->
		title('Заказы', ['Статус':'22%', 'Дата заказа':'22%', 'Телефон':'22%', 'Сумма заказа', 'Действия':'min']) + records each_record recs, ->
			status = db.status.records[rec.status_id]
			price = 0
			for r in db.find('order_item', rec.order_item_ids)
				if r
					price += r.price * r.quantity
			group tr [
				td (if status then "<p>#{status.name}</p>" else "<p>Без статуса</p>"), style: 'width: 22%'
				show_date 'created_at', "dd.MM.yyyy", style: 'width: 22%'
				show 'phone', style: 'width: 22%'
				td "<p>#{price.toCurrency()} руб.</p>"
				buttons()
			]
	belongs_to: ['status']
	has_many: ['order_item']
	select: ['created_at', 'phone', 'status_id']