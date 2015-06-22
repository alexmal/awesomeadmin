@component =
	setup: (el) ->
		$(el).parents('.component').toggleClass 'active'
	create: (el, name) ->
		el = $ el
		el.addClass 'loading'
		act.sendData el.parents('form').attr('action'), name: name, 'Компонент установлен', (d) ->
			if d
				el.removeClass 'loading'