@notify = (msg, params = {}) ->
	if params is 'green'
		params = icon: 'icon-checkmark', class: 'green', hide: true
	else if params is 'red'
		params = icon: 'icon-close', class: 'red', hide: true
	if params.btn
		if params.btn[0]
			params.btn = params.btn.reverse()
		else params.btn = [params.btn]
		for btn in params.btn
			if btn.ok?
				btn = click: btn.ok, class: 'green', text: "<i class=\"icon-checkmark\"></i>"
			else if btn.cancel?
				btn = click: btn.cancel, class: 'red', text: "<i class=\"icon-close\"></i>"
			msg += "<div class='btn #{btn.class}' onclick='#{btn.click || ''}; div = $(this).parent(); div.removeClass(\"show\"); setTimeout(function(){ div.remove() }, 300)'>#{btn.text}</div>"
	msg += "<i class='#{params.icon}'></i>" if params.icon
	attrs = html: msg
	attrs.id = params.id if params.id
	$div = $ '<div/>', attrs
	$div.appendTo app.notify
	div = $div[0]
	window.getComputedStyle(div).getPropertyValue "top"
	div.className = "show#{if params.class then ' ' + params.class else ''}"
	if params.hide
		setTimeout ->
			$div.removeClass 'show'
			setTimeout ->
				$div.remove()
			, 300
		, 3000