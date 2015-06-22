app.templates.index.category =
	tree: true
	order: 'position'
	page: (recs) ->
		ret = title 'Категории', ['Перетащить', 'Подкатегории', 'Товары', 'Название': 'max', 'Действия': 'p30']
		window.productCopySizesTb = treebox.gen
			header: "Скопировать размеры"
			treeboxAttrs:
				style: 'width: 181px'
			headerAttrs:
				class: "btn blue fade"
				style: "width: 155px; height: 36px; line-height: 36px; border-color: transparent"
			mainListAttrs:
				style: 'left: -118px; width: 367px'
			data:
				category:
					fields: ['name']
					has_self: true
					habtm:
						product:
							fields: ['name']
							pick: true
							group: 'Товары'
							has_many:
								size:
									fields: ['name']
									group: 'Размеры'
									pick: true
									has_many:
										color:
											fields: ['name']
											group: 'Цвета'
											has_many:
												texture:
													fields: ['name']
													group: 'Текстуры'
										option:
											fields: ['name']
											group: 'Опции'
			pickAction: 'productCopySizes(this)'
		ret + records each_record recs, category
	after: ->
		sort parents: true
		window.copyColorOptionTb = treebox.gen
			header: "Скопировать"
			treeboxAttrs:
				style: 'width: 109px'
			headerAttrs:
				class: "btn blue fade"
				style: "width: 84px; height: 36px; line-height: 36px; border-color: transparent"
			mainListAttrs:
				style: 'left: -118px; width: 367px'
			data:
				category:
					fields: ['name']
					has_self: true
					habtm:
						product:
							fields: ['name']
							group: 'Товары'
							has_many:
								size:
									fields: ['name']
									group: 'Размеры'
									pick: true
									has_many:
										color:
											fields: ['name']
											group: 'Цвета'
											has_many:
												texture:
													fields: ['name']
													group: 'Текстуры'
										option:
											fields: ['name']
											group: 'Опции'
			pickAction: 'copyColorOption(this)'
	ids: ['product']
	functions:
		category: ->
			html = drag() + btn_relation("Товары", "product") + show "name"
			html += new_child_link() + buttons()
			group tr(html), relations:
				has_self_open: category
				close:
					product: relation_model 'Товары', 'product', data: {ids: ['size']}, cb: ->
						group tr([
							btn_relation "Размеры", "size"
							show 'name'
							td productCopySizesTb, style: 'width: 1px'
							buttons()
						]), relations:
							close:
								size: relation_model 'Размеры', 'size', data: {ids: ['color', 'option']}, cb: ->
									group tr([
										btn_relation "Цвета", "color"
										btn_relation "Опции", "option"
										show 'name', style: 'width: 25%'
										show 'scode'
										currency 'price', style: 'width: 25%'
										td copyColorOptionTb, style: 'width: 109px'
										buttons()
									]), relations:
										close:
											color: relation_model 'Цвета', 'color', data: {ids: ['texture']}, cb: ->
												group tr([
													btn_relation "Текстуры", "texture"
													show 'name', style: 'width: 33%'
													show 'scode'
													currency 'price', style: 'width: 33%'
													buttons()
												]), relations:
													close:
														texture: relation_model 'Текстуры', 'texture', group: ['Изображение': 'min', 'Название / Код / Цена', 'Действия': 'min'], btn: true, cb: ->
															group tr("<td class='image' rowspan='3'>#{image_wrap(null, null, style: "max-height: 97px")}</td>" +
																input('name', 'Название', {}, colspan: 3)) +
																tr(input('scode', 'Код', {validation: {presence: true, async: 'textureValidation'}}) + save() + destroy()) +
																tr(input('price', 'Цена', {format: 'currency'}, colspan: 3))
											option: relation_model 'Опции', 'option', cb: ->
												group tr [
													show 'name', style: 'width: 33%'
													show 'scode', style: 'width: 33%'
													currency 'price', style: 'width: 33%'
													buttons()
												]
		textureValidation: (params) ->
			size_id = parseInt $("[name='size_id']").val()
			if size_id
				product_id = db.find_one('size', size_id).product_id
			if product_id
				p = model: 'size', where: {product_id: product_id}, has_many: {model: 'color', has_many: 'texture'}
				db.get p, ->
					was = params.el.data 'validateWas'
					br = false
					for size in db.select p
						for color in db.find 'color', size.color_ids
							for texture in db.find 'texture', color.texture_ids
								if params.val is texture.scode and params.val isnt was
									params.active = true
									params.msg.push 'Такое значение уже есть в товаре'
									br = true
									break
							break if br
						break if br
					params.uniq_cb params
			else params.uniq_cb params
		copyColorOption: (el) ->
			el = $ el
			to = parseInt el.data('val')
			$.post "/admin/record/copy_between_sizes", {from: el.parents('.group').data('id'), to: to}, (params) ->
				ready_find = db.size.ready.find
				for id in ready_find.ids
					index = id.records.indexOf to
					id.records.splice index, 1 unless index is -1
				index = ready_find.records.indexOf to
				ready_find.records.splice index, 1 unless index is -1
				app.route.page()
				notify 'Записи успешно скопированы'
			, 'json'
		productCopySizes: (el) ->
			next = $(el).next()
			if next.data('model') is 'size'
				find = [next.data 'id']
			else find = next.data('relations').has_many.size
			product_id = next.parents('.group').data 'id'
			data = copy: [
				{
					name: 'size'
					set:
						product_id: product_id
					find: find
					has_many: [
						{
							name: 'color'
							has_many: [
								{
									name: 'texture'
								}
							]
						}
						{
							name: 'option'
						}
					]			
				}
			]
			$.post "/admin/record/copy", data, (params) ->
				save = (options) ->
					for n, p of options
						for r in p
							db[n].records[r.record.id] = r.record
							if r.has_many
								save r.has_many
				save params
				ids = []
				for r in params.size
					ids.push r.record.id
				if db.product.records[product_id].size_ids
					db.product.records[product_id].size_ids = db.product.records[product_id].size_ids.concat ids
				else db.product.records[product_id].size_ids = ids
				app.route.page()
				notify 'Размеры успешно скопированы'
			, 'json'