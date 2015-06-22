app.addRoute 'model/:model', ->
	template = app.templates.index[param.model]
	window[k] = v for k, v of template.functions if template.functions
	cb = ->
		window.model = param.model
		if template.tree
			recs = []
			for r in db.select window.rec
				recs.push r unless r[param.model + '_id']
		else recs = db.select window.rec
		app.yield.html template.page recs
		delete window.rec
		template.after() if template.after
		if template.pagination
			paginator.wrap = $('#records')
			paginator.pages = $('#paginator')
			paginator.ready = [1]
			paginator.top = paginator.wrap.offset().top + parseInt paginator.wrap.css 'padding-top'
			paginator.load = false
			paginator.limit = template.pagination
			paginator.order = template.order or 'id'
			paginator.where = template.where or ''
			paginator.select = template.select or 'id'
			paginator.belongs_to = template.belongs_to
			paginator.has_many = template.has_many
			paginator.ids = template.ids
			paginator.scrollTop = $(window).scrollTop() - paginator.top
			paginator.page = 1
			$(window).scroll ->
				top = $(@).scrollTop() + paginator.top
				height = $(@).height()
				half = top + height / 2
				bottom = top + height
				pages = paginator.wrap.find('> .group')
				if paginator.scrollTop > top
					eq = -1
					for i in [1..paginator.page]
						eq += 1 if i in paginator.ready
					prev = pages.eq eq * paginator.limit
					offtop = prev.offset().top
					if !paginator.load and top < offtop
						unless paginator.page - 1 in paginator.ready
							paginator.load = true
							rec = model: param.model
							rec.offset = (paginator.page - 2) * paginator.limit
							rec.limit = paginator.limit
							rec.select = paginator.select if paginator.select
							rec.belongs_to = paginator.belongs_to if paginator.belongs_to
							rec.has_many = paginator.has_many if paginator.has_many
							rec.ids = paginator.ids if paginator.ids
							rec.order = paginator.order
							rec.where = paginator.where
							get = [rec]
							before = prev
							db.get get, ->
								ret = ''
								for rec in db.select rec
									window.rec = rec
									ret += record()
								was = paginator.wrap.height()
								before.before ret
								$(window).scrollTop $(window).scrollTop() + paginator.wrap.height() - was
								paginator.ready.push paginator.page - 1
								paginator.load = false
					if half < offtop
						paginator.page -= 1
						paginator.pages.find('.active').removeClass('active').prev().addClass('active')
				else
					eq = 0
					for i in [0..paginator.page - 1]
						eq += paginator.limit if i + 1 in paginator.ready
					next = paginator.wrap.find('> .group').eq eq - 1
					if next.length
						offtop = next.offset().top + next.height()
						if !paginator.load and bottom > offtop
							unless paginator.page + 1 in paginator.ready
								paginator.load = true
								rec = model: param.model
								rec.offset = paginator.page * paginator.limit
								rec.limit = paginator.limit
								rec.select = paginator.select if paginator.select
								rec.belongs_to = paginator.belongs_to if paginator.belongs_to
								rec.has_many = paginator.has_many if paginator.has_many
								rec.ids = paginator.ids if paginator.ids
								rec.order = paginator.order
								rec.where = paginator.where
								get = [rec]
								after = next
								db.get get, ->
									ret = ''
									for rec in db.select rec
										window.rec = rec
										ret += record()
									after.after ret
									paginator.ready.push paginator.page + 1
									paginator.load = false
						if half > offtop
							paginator.page += 1
							paginator.pages.find('.active').removeClass('active').next().addClass('active')
				paginator.scrollTop = top
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
		window.rec = model: param.model
		window.rec.limit = template.pagination if template.pagination
		window.rec.select = template.select if template.select
		if template.belongs_to
			window.rec.belongs_to = []
			window.rec.belongs_to.push bt for bt in template.belongs_to
		window.rec.has_many = template.has_many if template.has_many
		window.rec.ids = template.ids if template.ids
		window.rec.order = template.order if template.order
		window.rec.where = template.where if template.where
		window.rec.count = true if template.pagination
		if window.data
			db.collect window.data
			cb()
		else
			get = [window.rec]
			get.push p for p in template.get if template.get
			db.get get, cb
	else
		app.yield.html "<h2>Отсутствует шаблон страницы.</h2>"