@ask = (msg, params) ->
	ask = $('#ask').show()
	window.getComputedStyle(ask[0]).getPropertyValue "top"
	ask.addClass 'show'
	ask.find('.text p').html msg
	btn = ask.find '.ok'
	if params.ok
		if params.ok.html
			btn.html "<span>#{params.ok.html}</span>"
		if params.ok.class
			btn.attr 'class', 'btn ' + params.ok.class
	btn.off 'click'
	btn.click ->
		params.action()
		$('#ask').removeClass 'show'
		setTimeout ->
			$('#ask').hide()
		, 500
	if params.cancel
		ask.find('.cancel').click ->
			params.cancel()
			$('#ask').removeClass 'show'
			setTimeout ->
				$('#ask').hide()
			, 500
	else
		ask.find('.cancel').click ->
			$('#ask').removeClass 'show'
			setTimeout ->
				$('#ask').hide()
			, 500