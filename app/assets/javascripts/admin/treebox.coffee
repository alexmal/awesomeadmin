@treebox =
	toggle: (el) ->
		tree = $(el).parent()
		if tree.hasClass 'active'
			@close tree
		else
			tree.addClass 'active'
	close: (el) ->
		el.removeClass('active').find('.active').removeClass 'active'
		$('.open', el).removeClass 'open'
	gen: (params) ->
		params.header ?= 'Выбрать'
		params.pick ?= {}
		params.pick.val ?= 'id'
		params.pick.header ?= 'name'
		rec_id = params.rec.id if params.rec
		"<div class='treebox'
			#{if params.style then " style='#{params.style}'" else ''}
			data-treebox='#{JSON.stringify params.data}'
			data-pick='#{JSON.stringify params.pick}'
			data-pick-action='#{params.pickAction || 'treebox.pick(this)'}'
			#{if params.checkAction then "data-check-action='#{params.checkAction}'" else ''}
			#{if rec_id then " data-rec-id='#{rec_id}'" else ''}
			#{if params.notModel then " data-not-model='#{params.notModel}'" else ''}
			#{if params.notId then " data-not-id='#{params.notId}'" else ''}>
			<p data-default='#{params.header}' onclick='treebox.start(this)'>#{params.header}</p>
			<div class='wrap'></div>
			#{if params.input then "<input type='hidden' name='#{params.input.name}'#{if params.rec then " value='#{params.rec[params.pick.val]}'" else if params.input.value then " value='#{params.input.value}'" else ''}>" else ''}
		</div>"
	start: (el) ->
		tb = $(el).attr('onclick', 'treebox.toggle(this)').parent().addClass 'active'
		data = tb.data()
		wrap = tb.find '.wrap'
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
			ret = "<div><div class='item'><p><span>Отсутствуют записи</span></p></div></div>" if ret is ''
			wrap.html ret
	draw: (data, name, params, recs) ->
		ret = ""
		for rec in recs
			if !(name is data.notModel and rec.id is data.notId)
				arrow = false
				arrow_space = false
				if params.has_self
					arrow_space = true
					if rec[name + '_ids'].length then arrow = true
				relations = {}
				if params.has_many
					arrow_space = true
					relations.has_many = {}
					for k of params.has_many
						ids = rec[k + '_ids']
						arrow = true if ids.length
						relations.has_many[k] = ids
				if params.habtm
					arrow_space = true
					relations.habtm = {}
					for k of params.habtm
						ids = rec[k + '_ids']
						arrow = true if ids.length
						relations.habtm[k] = ids
				paddinLeft = 0
				ret += "<div><div class='item' data-relations='#{JSON.stringify relations}' data-id='#{rec.id}' data-model='#{name}' data-treebox='#{JSON.stringify params}'>"
				if params.pick is 'btn'
					paddinLeft += 33
					ret += "<i data-model='#{name}' class='icon-checkmark2#{if rec.id is data.recId then ' active' else ''}' data-val='#{rec[data.pick.val]}' data-header='#{rec[data.pick.header]}' onclick='#{data.pickAction}'></i>"
				ret += "<i style='left: #{paddinLeft}px' class='icon-arrow-down5' onclick='treebox.open(this)'></i>" if arrow
				paddinLeft += 33 if arrow_space
				if params.check
					ret += "<label style='left: #{paddinLeft}px' class='checkbox'>
						<div>
							<input type='checkbox' onchange='checkboxChange(this); treebox.checkbox(this)'>
						</div>
					</label>"
					paddinLeft += 33
				ret += "<p style='padding-left: #{paddinLeft}px' #{if params.pick is true then " class='pick#{if rec.id is data.recId then ' active' else ''}' data-val='#{rec[data.pick.val]}' data-header='#{rec[data.pick.header]}' onclick='#{data.pickAction}'" else ''}>#{("<span>#{rec[f]}</span>" for f in params.fields).join ''}</p></div></div>"
		ret
	drawGroup: (data, name, params, recs) ->
		ret = ""
		if recs.length > 0
			ret += "<div class='wrap'>"
			if params.group
				ret += "<div class='group'>"
				if params.check
					ret += "<label class='checkbox'>
						<div>
							<input type='checkbox' onchange='treebox.groupCheckbox(this)'>
						</div>
					</label>"
				ret += "<p#{if params.check then " style='left: 33px'" else ''}>#{params.group}</p></div>"
			ret += @draw data, name, params, recs
			ret += "</div>"
		ret
	open: (el) ->
		el = $ el
		item = el.parent()
		if el.hasClass 'active'
			el.removeClass 'active'
			item.parent().removeClass 'open'
			treebox_wrap = el.parents '.treebox'
			wrap = $ '> .wrap', treebox_wrap
			current_left = parseInt wrap.css 'left'
			setTimeout ->
				if current_left < 0
					right = wrap.offset().left + wrap.width()
					width = $(window).width()
					if right < width
						set = width - right + current_left
						wrap.animate left: set + 'px', 300 if set <= 0
			, 300
		else
			el.addClass 'active'
			parent = item
			parent.parent().addClass 'open'
			wrap = el.parents '.treebox'
			data = wrap.data()
			item_data = item.data()
			if el.data 'ready'
				setTimeout ->
					wrap = $ '> .wrap', wrap
					right = wrap.offset().left - parseInt(wrap.css 'left') + wrap.width()
					width = $(window).width()
					if right > width
						wrap.animate left: width - right + 'px', 300
				, 300
			else
				el.data 'ready', true
				params = []
				if item_data.treebox.has_self
					m = model: item_data.model, ids: [item_data.model], where: {}, select: []
					m.select.push f for f in item_data.treebox.fields
					m.select.push m.model + '_id' if m.model + '_id' not in m.select
					m.select.push 'id' if 'id' not in m.select
					m.where[item_data.model + '_id'] = item_data.id
					m.ids.push n for n, h of item_data.treebox.has_many if item_data.treebox.has_many
					m.ids.push n for n, h of item_data.treebox.habtm if item_data.treebox.habtm
					params.push m
				if item_data.treebox.has_many
					for n, h of item_data.treebox.has_many
						m = model: n, find: item_data.relations.has_many[n]
						if h.has_many
							m.ids = []
							m.ids.push a for a of h.has_many
						if h.habtm
							m.ids ?= []
							m.ids.push a for a of h.habtm
						params.push m
				if item_data.treebox.habtm
					for n, h of item_data.treebox.habtm
						m = model: n, find: item_data.relations.habtm[n]
						if h.has_many
							m.ids = []
							m.ids.push a for a of h.has_many
						if h.habtm
							m.ids ?= []
							m.ids.push a for a of h.habtm
						params.push m
				db.get params, ->
					ret = ""
					if item_data.treebox.has_many
						for k, v of item_data.treebox.has_many
							ret += treebox.drawGroup data, k, v, db.find k, item_data.relations.has_many[k] if item_data.relations.has_many[k].length
					if item_data.treebox.habtm
						for k, v of item_data.treebox.habtm
							ret += treebox.drawGroup data, k, v, db.find k, item_data.relations.habtm[k] if item_data.relations.habtm[k].length
					if item_data.treebox.has_self
						where = {}
						where[item_data.model + '_id'] = item_data.id
						ret += treebox.drawGroup data, item_data.model, item_data.treebox, db.where item_data.model, where
					item.after ret
					wrap = $ '> .wrap', wrap
					right = wrap.offset().left + wrap.width()
					width = $(window).width()
					wrap.animate left: width - right + 'px', 300 if right > width
	pick: (el) ->
		el = $ el
		tree = el.parents '.treebox'
		header = tree.find '> p'
		input = tree.find 'input'
		if el.hasClass 'active'
			el.removeClass 'active'
			header.removeClass('active').html header.data 'default'
			input.val ''
		else
			@close tree
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
	groupCheckbox: (el) ->
		checkboxes = $(el).parents('.wrap').first().find '.item .checkbox input'
		all_checked = true
		for c in checkboxes
			unless $(c).is(':checked')
				all_checked = false
				break
		if all_checked
			check = false
		else check = true
		el.checked = check
		checkboxChange el
		for c in checkboxes
			c.checked = check
			checkboxChange c
		@checkbox el
	checkbox: (el) ->
		tree = $(el).parents '.treebox'
		action = tree.data 'checkAction'
		window[action] tree, el if action and window[action]