app.templates.form.size =
	page: ->
		title('размер', absolute: true) + form(
			tr(tb "Товар", 'product', {data: {category: {fields: ['name'], has_self: true, habtm: product: {fields: ['name'], pick: true}}}}, attrs: colspan: 3)+
			tr(
				td(field("Название", "name", {validation: presence: true}), attrs: {width: "33.3%"}) +
				td(field("Код", "scode", {validation: {presence: true, async: 'sizeValidation'}}), attrs: {width: "33.3%"}) +
				td(field "Цена", "price", {format: {decimal: "currency"}, validation: true})
			)
		) + relation('цвета', 'color', ['Изображение': 'min', 'Название / Код / Цена / Описание', 'Действия': 'min'], ->
			group (tr("<td class='image' rowspan='3'>#{image_wrap(null, null, style: "max-height: 103px")}</td>" + input('name', 'Название') + save() + destroy()) +
				tr(input 'scode', 'Код', {validation: {presence: true, async: 'colorValidation'}}, colspan: 3) +
				tr(input 'price', 'Цена', {format: 'currency'}, colspan: 3) +
				tr(btn_relation("Текстуры", "texture") + input('description', 'Описание', {}, colspan: 3))
			), relations:
				close:
					texture: relation_model 'Текстуры', 'texture', group: ['Изображение': 'min', 'Название / Код / Цена', 'Действия': 'min'], btn: true, cb: ->
						group tr("<td class='image' rowspan='3'>#{image_wrap(null, null, style: "max-height: 103px")}</td>" +
							input('name', 'Название', {}, colspan: 3)) +
							tr(input('scode', 'Код', {validation: {presence: true, async: 'textureValidation'}}) + save() + destroy()) +
							tr(input('price', 'Цена', {format: 'currency'}, colspan: 3))
		) + relation 'опции', 'option', ['Изображение': 'min', 'Название / Код / Цена', 'Действия': 'min'], ->
			group tr("<td class='image' rowspan='3'>#{image_wrap('images', null, style: "max-height: 103px")}</td>" +
				input('name', 'Название', {}, colspan: 3)) +
				tr(input('scode', 'Код', {validation: {presence: true, async: 'optionValidation'}}) + save() + destroy()) +
				tr(input('price', 'Цена', {format: 'currency'}, colspan: 3))
	belongs_to: ["product"]
	has_many: [
		{model: "color", has_many: "texture"}
		{model: "option"}
	]
	functions:
		sizeValidation: (params) ->
			product_id = parseInt $("[name='product_id']").val()
			if product_id
				p = model: 'size', where: {product_id: product_id}
				db.get p, ->
					for size in db.select p
						if params.val is size.scode and params.val isnt params.el.data 'validateWas'
							params.active = true
							params.msg.push 'Такое значение уже есть в товаре'
							break
					params.uniq_cb params
			else params.uniq_cb params
		colorValidation: (params) ->
			product_id = parseInt $("[name='product_id']").val()
			if product_id
				p = model: 'size', where: {product_id: product_id}, has_many: 'color'
				db.get p, ->
					was = params.el.data 'validateWas'
					for size in db.select p
						for color in db.find 'color', size.color_ids
							if params.val is color.scode and params.val isnt was
								params.active = true
								params.msg.push 'Такое значение уже есть в товаре'
								break
					params.uniq_cb params
			else params.uniq_cb params
		optionValidation: (params) ->
			product_id = parseInt $("[name='product_id']").val()
			if product_id
				p = model: 'size', where: {product_id: product_id}, has_many: 'option'
				db.get p, ->
					was = params.el.data 'validateWas'
					for size in db.select p
						for option in db.find 'option', size.option_ids
							if params.val is option.scode and params.val isnt was
								params.active = true
								params.msg.push 'Такое значение уже есть в товаре'
								break
					params.uniq_cb params
			else params.uniq_cb params
		textureValidation: (params) ->
			product_id = parseInt $("[name='product_id']").val()
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