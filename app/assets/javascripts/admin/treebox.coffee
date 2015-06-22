@treebox =
	toggle: (el) ->
		$(el).parent().toggleClass 'active'
	pick: (el) ->
		el = $ el
		treebox = el.parents '.treebox'
		header = treebox.find '> p'
		input = treebox.find 'input'
		if el.hasClass 'active'
			el.removeClass 'active'
			header.removeClass('active').html header.data 'default'
			input.val ''
		else
			treebox.removeClass('active').find('.active').removeClass 'active'
			treebox.find('.open').removeClass 'open'
			el.addClass 'active'
			data = el.data()
			if data.header
				header.addClass('active').html data.header
			else if data.header is undefined
				header.addClass('active').html el.prev().html()
			if data.val
				input.val data.val
			else if data.val is undefined
				input.val el.prev().html()
			cb = @cb[treebox.data 'index']
			params =
				treebox: treebox
				header: header
				el: el
			for k, v of cb
				cb[k] params if cb[k]
	find_model: (model, hash) ->
		ret = false
		if hash[model]
			ret = hash[model]
		else
			for k, v of hash
				if v.habtm
					ret = @find_model model, v.habtm
					break if ret
		ret
	gen: (params) ->
		params.tag ?= 'div'
		params.header ?= 'Выбрать'
		index = $('.treebox').length
		cb = params.cb || {}
		params.headerAttrs ?= {}
		params.treeboxAttrs ?= {}
		@cb.push cb
		rec_id = params.rec.id if params.rec
		unless params.pick
			params.pick = val: 'id', header: 'name'
		else
			params.pick.val ?= 'id'
			params.pick.header ?= 'name'
		ret = "<#{params.tag}
			data-index='#{index}'
			data-treebox='#{JSON.stringify params.data}'
			data-pick='#{JSON.stringify params.pick}'
			data-pick-action='#{params.pickAction || 'treebox.pick(this)'}'
			#{if rec_id then " data-rec-id='#{rec_id}'" else ''}
			#{if params.colspan then " colspan='#{params.colspan}'" else ''}
			#{if params.rowspan then " rowspan='#{params.rowspan}'" else ''}
			#{if params.style then " style='#{params.style}'" else ''}
			#{if params.notModel then " data-not-model='#{params.notModel}'" else ''}
			#{if params.notId then " data-not-id='#{params.notId}'" else ''}"
		if params.treeboxAttrs.class
			params.treeboxAttrs.class += ' treebox'
		else params.treeboxAttrs.class = 'treebox'
		ret += " #{k}='#{v}'" for k, v of params.treeboxAttrs
		ret += "><p data-default='#{params.header}' onclick='treebox.start(this)'"
		if params.rec
			if params.headerAttrs.class
				params.headerAttrs.class += ' active'
			else params.headerAttrs.class = 'active'
			params.header = params.rec[params.pick.header]
		ret += " #{k}='#{v}'" for k, v of params.headerAttrs
		ret += ">#{params.header}</p><ul"
		ret += " #{k}='#{v}'" for k, v of params.mainListAttrs if params.mainListAttrs
		ret += "></ul>"
		if params.input
			ret += "<input type='hidden' name='#{params.input.name}'"
			if params.rec
				ret += " value='#{params.rec[params.pick.val]}'"
			else if params.input.value
				ret += " value='#{params.input.value}'"
			ret += ">"
		ret += "</#{params.tag}>"
	start: (el) ->
		tb = $(el).attr('onclick', 'treebox.toggle(this)').parent().addClass 'active'
		tb.find('> p').css 'width', '100%'
		data = tb.data()
		wrap = tb.find 'ul'
		get = []
		for k, v of data.treebox
			m = model: k, select: []
			m.select.push f for f in v.fields
			m.select.push 'id' if 'id' not in m.select
			if v.has_self
				m.where_null = [k + '_id']
				m.ids = [k]
				m.select.push m.model + '_id' if m.model + '_id' not in m.select
			if v.has_many
				m.ids ||= []
				for n, h of v.has_many
					m.ids.push n
			if v.habtm
				m.ids ||= []
				for n, h of v.habtm
					m.ids.push n
			get.push m
		db.get get, ->
			ret = ""
			for name, params of data.treebox
				if params.has_self
					where = {}
					where[name + '_id'] = null
					recs = db.where name, where
				else recs = db.all name
				ret += treebox.draw data, name, params, recs
			ret = "<li><p>Отсутствуют записи</p></li>" if ret is ''
			wrap.html ret
	draw: (data, name, params, recs) ->
		ret = ""
		for rec in recs
			if !(name is data.notModel and rec.id is data.notId)
				ret += "<li>"
				if params.pick
					ret += "<i data-model='#{name}' class='icon-checkmark2#{if rec.id is data.recId then ' active' else ''}' data-val='#{rec[data.pick.val]}' data-header='#{rec[data.pick.header]}' onclick='#{data.pickAction}'></i>"
				arrow = false
				if params.has_self
					arrow = true if rec[name + '_ids'].length
				relations = {}
				if params.has_many
					relations.has_many = {}
					for k of params.has_many
						ids = rec[k + '_ids']
						arrow = true
						relations.has_many[k] = ids
				if params.habtm
					relations.habtm = {}
					for k of params.habtm
						ids = rec[k + '_ids']
						arrow = true
						relations.habtm[k] = ids
				ret += "<i class='icon-arrow-down5' data-relations='#{JSON.stringify relations}' data-id='#{rec.id}' data-model='#{name}' data-treebox='#{JSON.stringify params}' onclick='treebox.open(this)'></i>" if arrow
				ret += "<p>"
				ret += "<span>#{rec[f]}</span>" for f in params.fields
				ret += "</p></li>"
		ret
	drawGroup: (data, name, params, recs) ->
		ret = ""
		if recs.length > 0
			ret += "<ul>"
			if params.group
				ret += "<li class='group'>
					<p class='capitalize'>#{params.group}</p>
				</li>"
			ret += @draw data, name, params, recs
			ret += "</ul>"
		ret
	open: (el) ->
		el = $ el
		if el.hasClass 'active'
			el.removeClass 'active'
			el.parent().removeClass 'open'
		else
			el.addClass 'active'
			parent = el.parent()
			parent.addClass 'open'
			treebox_data = el.parents('.treebox').data()
			data = el.data()
			unless data.ready
				el.data 'ready', true
				params = []
				if data.treebox.has_self
					m = model: data.model, ids: [data.model], where: {}, select: []
					m.select.push f for f in data.treebox.fields
					m.select.push m.model + '_id' if m.model + '_id' not in m.select
					m.select.push 'id' if 'id' not in m.select
					m.where[data.model + '_id'] = data.id
					m.ids.push n for n, h of data.treebox.has_many if data.treebox.has_many
					m.ids.push n for n, h of data.treebox.habtm if data.treebox.habtm
					params.push m
				if data.treebox.has_many
					for n, h of data.treebox.has_many
						m = model: n, find: data.relations.has_many[n]
						if h.has_many
							m.ids = []
							m.ids.push a for a of h.has_many
						if h.habtm
							m.ids ?= []
							m.ids.push a for a of h.habtm
						params.push m
				if data.treebox.habtm
					for n, h of data.treebox.habtm
						m = model: n, find: data.relations.habtm[n]
						if h.has_many
							m.ids = []
							m.ids.push a for a of h.has_many
						if h.habtm
							m.ids ?= []
							m.ids.push a for a of h.habtm
						params.push m
				db.get params, ->
					ret = ""
					if data.treebox.has_many
						for k, v of data.treebox.has_many
							ret += treebox.drawGroup treebox_data, k, v, db.find k, data.relations.has_many[k] if data.relations.has_many[k].length
					if data.treebox.habtm
						for k, v of data.treebox.habtm
							ret += treebox.drawGroup treebox_data, k, v, db.find k, data.relations.habtm[k] if data.relations.habtm[k].length
					if data.treebox.has_self
						where = {}
						where[data.model + '_id'] = data.id
						ret += treebox.drawGroup treebox_data, data.model, data.treebox, db.where data.model, where
					el.parent().append ret
	out_click: ->
		$('html').click ->
			$('.treebox').removeClass 'active'
		$('.treebox').click (event) ->
		    event.stopPropagation()
	cb: []