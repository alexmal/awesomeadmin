@rippleOut = (el, color) ->
	div = $ '<div/>', class: 'ripple-out'
	div.appendTo el
	window.getComputedStyle(div[0]).getPropertyValue "top"
	div.css('background-color': color) if color
	div.addClass 'scale'
	setTimeout ->
		div.remove()
	, 2000

@ripple = (event, el) ->
	elHeight = el.offsetHeight
	elWidth = el.offsetWidth
	pageX = event.pageX
	pageY = event.pageY
	offset = $(el).offset()
	pointerY = pageY - offset.top
	pointerX = pageX - offset.left
	calcDiag = (a, b) -> Math.sqrt a * a + b * b
	topLeftDiag = calcDiag pointerX, pointerY
	topRightDiag = calcDiag elWidth - pointerX, pointerY
	botRightDiag = calcDiag elWidth - pointerX, elHeight - pointerY
	botLeftDiag = calcDiag pointerX, elHeight - pointerY
	rippleRadius = Math.max topLeftDiag, topRightDiag, botRightDiag, botLeftDiag
	rippleSize = rippleRadius * 2
	left = pointerX - rippleRadius
	top = pointerY - rippleRadius
	div = $ '<div/>', class: 'ripple'
	div.appendTo el
	window.getComputedStyle(div[0]).getPropertyValue "top"
	div.css(width: rippleSize + "px", height: rippleSize + "px", left: left + "px", top: top + "px").addClass 'scale'
	setTimeout ->
		div.remove()
	, 2000