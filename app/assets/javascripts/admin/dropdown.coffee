@dropdown =
	toggle: (el) ->
		el = $ el
		if el.hasClass 'active'
			el.removeClass 'active'
		else
			if el.data 'ready'
				el.addClass 'active'
			else
				data = el.data()
				select_params = model: data.model, select: data.field
				db.get select_params, ->
					ret = ''
					if data.choosed then id = parseInt data.choosed else id = 0
					for rec in db.select select_params
						ret += "<p#{if rec.id is id then " class='active'" else ''} onclick='dropdown.pick(this, #{rec.id})'><span>#{rec[data.field]}</span></p>"
					$('> div', el).html ret
					el.addClass 'active'
					el.data 'ready', true
	pick: (el, val) ->
		el = $ el
		list = el.parent()
		$('> .active', list).removeClass 'active'
		el.addClass 'active'
		list.prev().html el.html()
		list.next().val val