app.templates.index.status =
	page: (recs) ->
		cb = -> group tr input('name', '', validation: presence: true) + save() + destroy()
		title('Статусы заказов', ['Название':'max', 'Действия':'225px'], add: cb) + records each_record recs, cb