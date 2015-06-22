app.templates.form.option =
	page: ->
		title('опция') + form tr(tb "Размер", 'size', {data: {category: {fields: ['name'], has_self: true, habtm: product: {fields: ['name'], has_many: size: {fields: ['name'], pick: true}}}}}, colspan: 3) +
		tr(
			input("Название", "name", {validation: presence: true}, width: "33.3%") +
			input("Код", "scode", {validation: {presence: true, async: 'optionValidation'}}, width: "33.3%") +
			input "Цена", "price", {format: {decimal: "currency"}, validation: true}
		) + tr td image_field('images', 'Добавить изображение'), colspan: 3
	belongs_to: ["size"]
	functions:
		optionValidation: (params) ->
			size_id = parseInt $("[name='size_id']").val()
			if size_id
				product_id = db.find_one('size', size_id).product_id
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