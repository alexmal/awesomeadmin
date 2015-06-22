#= require jquery
#= require jquery_ujs
#= require_self
#= require_tree

@app =
	routesSorted: {}
	data:
		route: {}
	aclick: (el, options) ->
		if window.history and history.pushState
			event.preventDefault()
			@options ||= {}
			@options.ref = @pathname
			app.go $(el).attr 'href'
	redirect: (path, options) ->
		if window.history and history.pushState
			@options ||= {}
			@options.ref = @pathname
			app.go path
		else window.location.href path
	routeFind: []
	routes: {}
	templates:
		index: {}
		form: {}
app.addRoute = (name, page) ->
	@routes[name] = page
	@routeFind.push name.split '/'
app.go = (url, params) ->
	unless @pathname is url
		@pathname = url
		history.pushState {}, '', url
	@pathArray = @pathname.split('?')[0].split('/')[2..-1]
	@path = @pathArray.join '/'
	len = @pathArray.length
	find = []
	for f in app.routeFind
		if f.length is len
			find.push f
	routeArray = []
	window.param = {}
	for f in find
		for a, i in f
			if a[0] is ':'
				window.param[a[1..-1]] = @pathArray[i]
			else if a isnt @pathArray[i]
				break
			routeArray.push a
		if routeArray.length is len
			break
		else
			routeArray = []
	routeString = routeArray.join '/'
	@route = @routes[routeString]
	app.qparam = {}
	query = window.location.search.substring 1
	vars = query.split '&'
	i = 0
	while i < vars.length
		pair = vars[i].split '='
		if typeof app.qparam[pair[0]] == 'undefined'
			app.qparam[pair[0]] = pair[1]
		else if typeof app.qparam[pair[0]] == 'string'
			arr = [
				app.qparam[pair[0]]
				pair[1]
			]
			app.qparam[pair[0]] = arr
		else
			app.qparam[pair[0]].push pair[1]
		i++
	@route()
	delete window.data if window.data
	params.cb() if params and params.cb
	app.menu.find(".current").removeClass 'current'
	cur = app.menu.find "[href='#{app.pathname}']"
	cur.parent().addClass 'current'
	cur.addClass 'current' if cur.hasClass 'action-right'
@menu =
	model: (model, name, icon = 'icon-stack') ->
		"<div class='item'>
			<a class='action-right' href='/admin/model/#{model}/new' onclick='app.aclick(this)'><i class='icon-plus'></i></a>
			<a class='name' href='/admin/model/#{model}' onclick='ripple(event, this); app.aclick(this)'><i class='#{icon}'></i><span>#{name}</span><div class='ripple'></div></a>
		</div>"
	index: (model, name, icon = 'icon-stack') ->
		"<div class='item'>
			<a class='name' href='/admin/model/#{model}' onclick='ripple(event, this); app.aclick(this)'><i class='#{icon}'></i><span>#{name}</span><div class='ripple'></div></a>
		</div>"
	html: (role) ->
		app.menu.html "<div class='item'><a href='/' onclick='ripple(event, this)' class='name'><i class='icon-home4'></i>На главную<div class='ripple'></div><div class='ripple'></div></a></div>#{if menu[role] then menu[role]().join '' else ''}<div class='item'><a rel='nofollow' onclick='ripple(event, this)' class='name' data-method='delete' href='/admin/logout'><i class='icon-exit'></i>Выход<div class='ripple'></div></a></div>"
ready = ->
	app.yield = $ '#main'
	if !app.menu
		app.menu = $ '#menu'
		menu.html me.role if me?
	app.notify = $ '#notify'
	if welcome_page?
		app.routes.welcome()
	else
		app.go app.pathname = window.location.pathname
$(document).ready ready