app.templates.form.product =
	page: ->
		ret = tr tb "Статус", 'extension', {data: {extension: {fields: ['name'], pick: true}}}, colspan: 3
		ret += tr tb "Категория", 'category', {data: {category: {fields: ['name'], pick: true, has_self: true}}}, colspan: 3
		ret += tr td habtm_checkboxes("Категории", "category", "name", 6), colspan: 3
		ret += tr [
			input "name", "Название", {validation: presence: true}, style: "width: 33.3%"
			input "scode", "Код", {validation: {presence: true, uniq: true}}, style: "width: 33.3%"
			input "price", "Цена", {format: {decimal: "currency"}, validation: true}
		]
		ret += tr [
			input "seo_title", "SEO title"
			input "seo_keywords", "SEO keywords (через запятую)"
			input "position", "Позиция", {}, style: "width: 33.3%"
		]
		ret += tr [
			checkbox "Отображать на главной странице", "main"
			checkbox "Отображать на панели скидки", "action"
			checkbox "Отображать на панели Хиты продаж", "best"
		]
		ret += tr [
			checkbox "Сделать Невидимым", "invisible"
			checkbox "Сделать Разделителем", "delemiter"
		]
		ret += tr td images(), colspan: 3
		ret += tr text {"Описание": "description", "Короткое описание": "shortdesk", "SEO description": "seo_description": "textarea"}, colspan: 3
		title('товар') + form ret
	belongs_to: ["extension"]
	has_many: "image"
	ids: "category"
	get: [{model: "category", select: ['id', 'name']}]