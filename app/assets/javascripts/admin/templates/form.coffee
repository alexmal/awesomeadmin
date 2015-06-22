page = ->
	$(window).off 'scroll'
	name = param.model
	template = app.templates.form[name]
	param.id = parseInt param.id
	id = param.id
	window[k] = v for k, v of template.functions if template.functions
	cb = ->
		id = parseInt param.id
		if id
			window.rec = db[param.model].records[id]
		else window.rec = false
		window.model = param.model
		app.yield.html template.page() + "<link rel='stylesheet' type='text/css' href='/lightbox/lightbox.min.css'><script src='/tinyMCE/tinymce.min.js'><script src='/lightbox/lightbox.min.js'>"
		addFormCb()
		delete window.rec
	window.relation = (name, model, group, cb) ->
		ret = "<div style='padding: 15px 30px 0'>#{header name, btn: ['Добавить', "#{model}_relation_add(this, \"#{model}\")"], group: group}<div class='records' data-model='#{window.model}' data-id='#{window.rec.id}'>"
		page_rec = window.rec
		page_model = window.model
		window.model = model
		for rec in db.find model, window.rec[model + '_ids'].reverse()
			window.rec = rec
			ret += cb()
		window.rec = page_rec
		window.model = page_model
		window["#{model}_relation_add"] = (el, model) ->
			window.model = model
			$(el).parents('.header').next().prepend cb()
		ret + "</div></div>"
	window.form = (html) ->
		"<form class='content form' data-model='#{window.model}'#{if window.rec then " data-id='#{window.rec.id}'" else ''}><table>#{html}</table></form>"
	window.title = (name, params = {}) ->
		params.btn ?= [(if window.rec then 'Сохранить' else 'Добавить'), 'formSaveRecord(this)']
		params.top = true
		header name, params
	window.text = (texts, attrs) ->
		ret = "<div class='nav-tabs'>"
		active = true
		for n of texts
			ret += "<p onclick='openTab(this)' class='#{if active then active = false; 'active ' else ''}capitalize'>#{n}</p>"
		ret += "</div><div class='tabs'>"
		active = true
		for n, f of texts
			if typeof f is 'string'
				ret += "<div data-field='#{f}' #{if active then active = false; " class='active'" else ''}><textarea class='tinyMCE' rows='25' name='#{f}' value='#{if window.rec then window.rec[f] else ''}'></textarea></div>"
			else
				for n, t of f
					ret += "<div class='textarea-wrap#{if active then active = false; " active" else ''}'><textarea name='#{n}'>#{if window.rec then window.rec[n] || '' else ''}</textarea></div>"
		td ret + "</div>", attrs
	window.addFormCb = ->
		if tinymce?
			tinymce.init selector: ".tinyMCE", plugins: 'link image code textcolor', language : 'ru', setup: (editor) ->
				editor.on 'init', (ed) ->
					editor.setContent $(ed.target.editorContainer).next().toggleClass('tinyMCE tinyMCE-ready').attr 'value'
		$(".images-form").sortable
			revert: true
			update: (e, ui) ->
				urls = []
				wrap = $ e.target
				wrap.find('[data-id] a').each -> urls.push $(@).attr 'href'
				if urls.length
					id = wrap.data 'recordId'
					model = wrap.data 'model'
					$.post '/admin/images_sort', urls: urls, id: id, model: model, ->
						for image, i in models[model].find(id).images()
							image.url = urls[i]
					, 'json'
	if window.data
		db.collect window.data
		cb()
	else
		get = []
		if param.id
			rec = model: param.model, find: param.id
			if template.belongs_to
				rec.belongs_to = []
				rec.belongs_to.push bt for bt in template.belongs_to
			rec.has_many = template.has_many if template.has_many
			rec.ids = template.ids if template.ids
			get.push rec
		get.push p for p in template.get if template.get
		if get.length
			db.get get, cb
		else cb()
app.addRoute 'model/:model/new', page
app.addRoute 'model/:model/edit/:id', page