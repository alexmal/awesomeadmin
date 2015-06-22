app.templates.index.extension =
	page: (recs) ->
		cb = -> group(
			tr(
				td(image_wrap(), rowspan: 3, style: 'width: 1px; height: 100px') +
				td('', style: 'border-width: 1px 0 0') +
				td('&nbsp;', colspan: 2, style: 'border-width: 1px')
			) +
			tr(
				input('name', '', {validation: {presence: true}, attrs: style: 'max-width: 350px'}, style: 'border-width: 0') +
				save() +
				destroy(),
				style: 'height: 36px'
			) +
			tr td('', style: 'border-width: 0 0 1px') + td('&nbsp;', colspan: 2, style: 'border-width: 1px')
		)
		title('Статусы товаров', ['Изображение': '188px', 'Название', 'Действия':'min'], add: cb) + records each_record recs, cb