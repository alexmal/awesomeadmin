app.addRoute 'model/:model', ->
	template = app.index[param.model]
	window[k] = v for k, v of template.functions if template.functions
	cb = ->
		window.model = param.model
		if template.tree
			recs = []
			for r in db.select window.select_params
				recs.push r unless r[param.model + '_id']
		else recs = db.select window.select_params
		app.yield.html template.page recs
		delete window.rec
		template.after() if template.after
		paginator.gen window.select_params
	window.title = (name, group, params) ->
		params ?= {}
		params.top = true
		params.group = group
		if params.add
			window[window.model + '_render'] = params.add
			window[window.model + '_add'] = (el, f) -> $(el).parents('.header').next().prepend window[f]()
			params.btn = ['Добавить', window.model + "_add(this, \"#{window.model}_render\")"]
		else params.link ?= ['Добавить', "/admin/model/#{param.model}/new"]
		header name, params
	window.records = (html) -> "<div id='records' data-model-wrap='#{param.model}'>#{html}</div>"
	window.show_image = (name, params, header) ->
		params ?= {}
		if params.attrs
			if params.attrs.class
				params.attrs.class += ' image'
			else params.attrs.class = 'image'
		else params.attrs = class: 'image'
		if header
			image_field header, name, params
		else
			url = window.rec[name]
			td "<a href='#{url}' data-lightbox='#{window.model}'><img src='#{url}'></a>", params
	window.sort = (params) ->
		if params
			if params.parents
				$("[data-model-wrap=#{window.model}]").sortable
					items: "[data-model=#{window.model}]"
					connectWith: "[data-model-wrap=#{window.model}]"
					revert: true
					handle: '.drag-handler'
					update: (e, ui) ->
						wrap = $ @
						parent = wrap.parents('.group').eq(0)
						if parent.length
							parent_id = parent.data 'id'
						else parent_id = 'nil'
						ids = []
						wrap.find("> [data-model='#{window.model}']").each -> ids.push $(@).data 'id'
						$.post '/admin/record/sort_with_parent', ids: ids, parent_id: parent_id, model: window.model
		else
			$("#records").sortable
				items: "[data-model=#{window.model}]"
				revert: true
				handle: '.drag-handler'
				update: (e, ui) ->
					group = $ @
					parent = group.parent()
					ids = []
					parent.find("[data-model=#{window.model}]").each -> ids.push $(@).data 'id'
					$.post '/admin/record/sort_all', ids: ids, model: model
	if template
		window.select_params = $.extend model: param.model, data_rb.index[param.model]
		if window.data
			db.collect window.data
			cb()
		else
			db.get window.select_params, cb
	else
		app.yield.html "<h2>Отсутствует шаблон страницы.</h2>"