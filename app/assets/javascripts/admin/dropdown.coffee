@dropdown =
	toggle: (el) ->
		$(el).toggleClass 'active'
	pick: (el) ->
		el = $ el
		val = el.data 'val'
		html = el.html()
		dropdown = el.parents('.dropdown')
		dropdown.find('input').val(val or html)
		dropdown.find('.active').removeClass 'active'
		el.addClass 'active'
		dropdown.find('> p').html html
	gen: (d) ->
		d.head ||= 'Выбрать'
		ret = "<div class='dropdown' onclick='dropdown.toggle(this)'><p>#{d.head}</p><div>"
		for l in d.list
			ret += "<p"
			ret += " class='active'" if d.active and d.active is l
			ret += " onclick='dropdown.pick(this)'"
			if typeof l is 'string'
				ret += ">#{l}"
			else
				ret += " data-val='#{l.val}'" if l.val
				ret += ">#{l.name}"
			ret += "</p>"
		ret + "</div><input type='hidden' name='#{d.name}'></div>"