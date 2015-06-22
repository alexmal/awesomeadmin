app.templates.form.order =
	page: ->
		ret = cells [
			[
				td ''
				tb "Статус", 'status', data: {status: {fields: ['name'], pick: true}}
				td ''
			]
			input "created_at", "Дата заказа", format: date: "dd.MM.yyyy"
			[
				input 'last_name', 'Фамилия', format: not_null: true
				input 'first_name', 'Имя', format: not_null: true
				input 'middle_name', 'Отчество', format: not_null: true
			]
			[
				input 'addr_street', 'Улица', format: not_null: true
				input 'addr_block', 'Подъезд', format: not_null: true
				input 'addr_home', 'Дом', format: not_null: true
			]
			[
				input 'addr_flat', 'Квартира', format: not_null: true
				input 'gender', 'Пол', format: not_null: true
				input 'pay_type', 'Способ оплаты', format: not_null: true
			]
			[
				input 'phone', 'Телефон', format: not_null: true
				input 'email', 'E-mail', format: not_null: true
			]
		]
		ret += "<td colspan='3'>
			<table class='style' style='white-space: nowrap'>
				<tr>
					<th>№ п/п</th>
					<th>Наименование изделия</th>
					<th>Размер</th>
					<th>Цвет</th>
					<th>Опция</th>
					<th>Цена за ед.</th>
					<th>Кол-во</th>
					<th colspan='2'>Сумма</th>
				</tr>"
		i = 0
		quantity = 0
		total = 0
		for c in db.where('order_item', order_id: param.id)
			p = db.find('product', c.product_id)[0]
			quantity += c.quantity
			price = c.price * c.quantity
			total += price
			ret += "<tr>
				<td>#{i += 1}</td>
				<td>#{p.name}</td>"
			if c.size_scode is ''
				ret += "<td>Стандартный</td>"
			else
				ret += "<td>#{c.size} (#{c.size_scode})</td>"
			if c.color_scode is ''
				ret += "<td>Стандартный</td>"
			else if c.texture_scode is ''
				ret += "<td>#{c.color} (#{c.color_scode})</td>"
			else ret += "<td><p>Каталог цветов #{c.color} (#{c.color_scode})</p><p>Текстура #{c.texture} (#{c.texture_scode})</p></td>"
			if c.option_scode is ''
				ret += "<td>Без опции</td>"
			else
				ret += "<td>#{c.option} (#{c.option_scode})</td>"
			ret += "<td>#{c.price.toCurrency()} руб.</td>
				<td>#{c.quantity}</td>
				<td colspan='2' class='price'>#{price.toCurrency()} руб.</td>
			</tr>"
		ret += "<tr>
			<td colspan='4' class='tar pad'><b>Стоимость товара</b></td>
			<td style='color: red'><b>#{quantity}</b></td>
			<td>шт.</td>
			<td colspan='2'>#{total.toCurrency()} руб.</td>
		</tr>
		<tr>
			<td colspan='4' class='tar pad'><b>Итого</b></td>
			<td colspan='2'></td>
			<td colspan='2' id='itogo'>#{(total).toCurrency()} руб.</td>
		</tr>"
		ret += "</table></td>"
		title('заказ') + form ret
	belongs_to: ["status"]
	has_many: [
		model: 'order_item', belongs_to: ["product"]
	]