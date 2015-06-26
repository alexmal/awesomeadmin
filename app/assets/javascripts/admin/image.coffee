@image =
	upload: (input) ->
		if input.files
			label = $(input).parent()
			container = label.parent()
			if container.hasClass 'images-container'
				index = container.find('> label').length
				images = container.prev()
				for f, i in input.files
					reader = new FileReader()
					reader.i = i
					reader.index = index
					reader.onload = (e) ->
						images.append "<div class='image'>
								<div class='btn red remove' onclick='window.image.removeNewImage(this, #{@.i}, #{@.index})'></div>
								<a href='#{e.target.result}' data-lightbox='product'><img src='#{e.target.result}'></a>
							</div>"
					reader.readAsDataURL f
				label.after(label.clone true).addClass 'hide'
			else
				attrs = label.data 'attrs'
				reader = new FileReader()
				reader.onload = (e) ->
					label.before "<div class='image'>
							<div class='btn red remove' onclick='window.image.removeNewOneImage(this)'></div>
							<a href='#{e.target.result}' data-lightbox='product'><img#{if attrs then " #{attrs}" else ''} src='#{e.target.result}'></a>
						</div>"
				reader.readAsDataURL input.files[0]
				label.hide()
	removeImage: (el) ->
		$(el).parent().addClass('hidden').html "<input type='hidden' name='removeImages'>"
	removeNewImage: (el, image_index, input_index) ->
		div = $(el).parent()
		container = div.parent().next()
		data = container.data 'removeNew'
		if data
			data.push "#{input_index}-#{image_index}"
			container.data 'removeNew', data
		else
			container.data 'removeNew', ["#{input_index}-#{image_index}"]
		div.remove()
	removeNewOneImage: (el) ->
		div = $(el).parent()
		label = div.next().show()
		input = label.find 'input'
		input.replaceWith(input = input.clone true)
		div.remove()
	removeOneImage: (el, field, val) ->
		$(el).parent().before "<input name='removeImage' type='hidden' data-field='#{field}' value='#{val}'>"
		@removeNewOneImage el
	broken: (el) ->
		$(el).replaceWith "<div class='broken'><i class='icon-image'></i></div>"