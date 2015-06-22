app.templates.form.color =
	page: ->
		title('цвет', absolute: true) +
		form(
			tr(tb "Размер", 'size', {data: {category: {fields: ['name'], has_self: true, habtm: product: {fields: ['name'], has_many: size: {fields: ['name'], pick: true}}}}}, attrs: colspan: 3) +
			tr(td image_field('image', 'Добавить изображение'), attrs: colspan: 3) +
			tr([
				input "name", "Название", {validation: presence: true}, attrs: {width: "33.3%"}
				input "scode", "Код", {validation: {presence: true, async: 'colorValidation'}}, attrs: {width: "33.3%"}
				input "price", "Цена", {format: {decimal: "currency"}, validation: true}
			]) +
			tr text {'Описание': 'description'}, attrs: colspan: 3
		) +
		relation 'текстуры', 'texture', ['Изображение': 'min', 'Название / Код / Цена', 'Действия': 'min'], ->
			group tr("<td class='image' rowspan='3'>#{image_wrap(null, null, style: "max-height: 97px")}</td>" + input('name', 'Название', {}, colspan: 3)) +
				tr(input('scode', 'Код', {validation: {presence: true, async: 'textureValidation'}}) + save() + destroy()) +
				tr(input('price', 'Цена', {format: 'currency'}, colspan: 3))
	belongs_to: ["size"]
	has_many: ["texture"]
	functions:
		colorValidation: (params) ->
			size_id = parseInt $("[name='size_id']").val()
			if size_id
				product_id = db.find_one('size', size_id).product_id
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