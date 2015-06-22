app.templates.form.category =
	page: ->
		title('категория') + form(
			tr(tb "Категория", 'category', {data: {category: {fields: ['name'], pick: true, has_self: true}}}, colspan: 2) +
			tr(
				input("name", "Название", {validation: presence: true}, width: "50%") +
				input "scode", "Код", {validation: {presence: true, uniq: true}}, width: "50%"
			) +
			tr(
				input("commission", "Наценка продавца") +
				input "rate", "Наша наценка"
			) +
			tr(
				input("seo_title", "SEO title") +
				input "seo_keywords", "SEO keywords (через запятую)"
			) +
			tr(td image_field('header', 'Добавить изображение заголовка'), colspan: 2) +
			tr(td images(), colspan: 2) +
			tr text {"Описание": "description", "SEO description": "seo_description": "textarea"}, colspan: 2
		)
	belongs_to: ["category"]