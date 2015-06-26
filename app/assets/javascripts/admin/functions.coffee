Number.prototype.toCurrency = ->
	(""+this.toFixed(2)).replace(/\B(?=(\d{3})+(?!\d))/g, " ")
String.prototype.toNumber = ->
	parseFloat @replace(/\ /g,'')
String.prototype.toCurrency = ->
	@toNumber().toCurrency()
String.prototype.classify = ->
	(@charAt(0).toUpperCase() + @slice(1)).replace /(\_\w)/g, (m) -> m[1].toUpperCase()

@checkboxChange = (el) ->
	parent = $(el).parent()
	if el.checked
		parent.addClass 'checked'
		rippleOut parent[0], 'rgba(0, 188, 212, .5)'
	else
		parent.removeClass 'checked'
		rippleOut parent[0], 'rgba(0, 0, 0, .3)'

@each_record = (recs, cb) ->
	ret = ''
	for rec in recs
		window.rec = rec
		ret += cb()
	ret

@relationToggle = (el, rel) ->
	el = $ el
	relations = el.parents('table').eq(0).next()
	wrap = relations.find "> div[data-model-wrap='#{rel}']"
	if wrap.hasClass 'active'
		el.removeClass 'always'
		wrap.removeClass 'active'
		unless relations.find('> .active, > .start').length
			relations.removeClass 'active'
	else
		el.addClass 'always'
		wrap.addClass 'active'
		relations.addClass 'active'
		unless wrap.data 'ready'
			if parseInt(el.find('.relations-count').html()) is 0
				wrap.data 'ready', true
			else
				data = wrap.data('data') or {}
				params = model: rel
				params.ids = data.ids if data.ids
				ids = wrap.data 'ids'
				params.find = ids
				db.get params, ->
					window.model = rel
					ret = ""
					render = window["#{rel}_relation_render"]
					for rec in db.find rel, ids
						window.rec = rec
						ret += render()
					delete window.rec
					wrap.data('ready', true).append ret

@groupSaveRecord = (el) ->
	form = $(el).parents('table').first()
	group = form.parent()
	bt = group.parent().data()
	saveRecord form, group.data(), bt, create: (form, id) ->
		form.parent().data 'id', id
		notify 'Запись создана', 'green'
@formSaveRecord = (el) ->
	form = $(el).parents('.header').next()
	saveRecord form, form.data(), {}, create: (form, id) ->
		app.go "/admin/model/#{form.data 'model'}/edit/#{id}", cb: -> notify 'Запись создана', 'green'
@saveRecord = (form, group, bt, params) ->
	return false if group.beforeSave and window[group.beforeSave](form) is false
	form.find("[data-validate]").each -> validate @
	return if form.find('.validation.active').length
	fd = new FormData()
	data = fields: {}
	if bt.model and bt.id
		data.fields[bt.model + '_id'] = bt.id
		fd.append "fields[#{bt.model + '_id'}]", bt.id
	form.find('input, textarea').each ->
		el = $ @
		unless el.data 'ignore'
			switch @name
				when 'image-file'
					file = @files[0]
					fd.append "image[#{el.data 'field'}]", file if file
				when 'images-file'
					if @files.length
						label = el.parent()
						label_index = label.index() + 1
						removeNew = label.parent().data 'removeNew'
						for image, i in @files
							if !removeNew or "#{label_index}-#{i}" not in removeNew
								fd.append "images[]", image
				when 'removeImage'
					field = el.data 'field'
					data.fields[field] = ''
					fd.append "removeImage[]", field
				when 'removeImages'
					remove_id = el.parent().data 'id'
					data.removeImages ?= []
					data.removeImages.push remove_id
					fd.append "removeImages[]", remove_id
				when 'habtm_checkboxes'
					field = el.data 'field'
					unless data.fields[field]
						data.fields[field] = []
						unless el.parents('.checkboxes').eq(0).find('input:checked').length
							fd.append "fields[#{field}]", []
					if @checked
						data.fields[field].push parseInt @value
						fd.append "fields[#{field}][]", @value
				else
					if @type is 'checkbox'
						value = @checked
					else if @tagName is 'INPUT'
						value = @value
						format = el.data 'format'
						if format
							if format is 'currency'
								value = parseFloat(value.replace(' ', '')) unless value is ''
							else if format.date
								value = Date.parseExact value, format.date unless value is ''
					else if el.hasClass 'tinyMCE-ready'
						value = tinyMCE.get(@id).getContent()
					else
						value = @value
					data.fields[@name] = value
					fd.append "fields[#{@name}]", value
	if group.id
		url = "/admin/db/#{group.model}/update/#{group.id}"
	else url = "/admin/db/#{group.model}/create"
	$.ajax
		url: url
		data: fd
		type: 'POST'
		contentType: false
		processData: false
		dataType: "json"
		success: (res) ->
			if res is 'permission denied'
				notify 'Доступ запрещен', 'red'
			else
				if group.id
					rec = db[group.model].records[group.id]
					for k, v of data.fields
						rec[k] = v
					notify 'Запись обновлена', 'green'
				else
					rec = db[group.model].records[res.id] = {}
					db[group.model].ready.find.records.push res.id
					where =
						id:
							'':
								ids: []
								records:
									all: false
									positions: []
								select: []
					for k, v of data.fields
						if k[-3..-1] is '_id'
							bt_rec = db[k[0..-4]].records[v]
							bt_rec[group.model + '_ids'].push res.id if bt_rec and bt_rec[group.model + '_ids']
							w = db[group.model].ready.where.id["#{k[0..-4]}_id = #{v}"]
							if w and w.records.all
								where.id["#{k[0..-4]}_id = #{v}"] =
									ids: []
									records:
										all: true
										positions: w.records.positions.concat res.id
									select: []
						rec[k] = v
					db[group.model].ready.where = where
				if data.removeImages
					for id in data.removeImages
						rec.image_ids.splice rec.image_ids.indexOf(id), 1
						db.image.ready.find.records.splice db.image.ready.find.records.indexOf(id), 1
						for order, order_hash of db.image.ready.where
							for where, where_hash of order_hash
								change_count = false
								for h in where_hash.ids
									index = h.records.positions.indexOf id
									unless index is -1
										h.records.positions.splice index, 1
										change_count = true
								index = where_hash.records.positions.indexOf id
								unless index is -1
									where_hash.records.positions.splice index, 1
									change_count = true
								for h in where_hash.select
									index = h.records.positions.indexOf id
									unless index is -1
										h.records.positions.splice index, 1
										change_count = true
								where_hash.count -= 1 if where_hash.count and change_count
						delete db.image.records[id]
				if res.image
					for k, v of res.image
						rec[k] = v
				if res.images
					for image in res.images
						rec.image_ids ?= []
						rec.image_ids.push image.id
						db.image.records[image.id] = image
						db.image.ready.find.records.push image.id
				params.create form, res.id unless group.id

@removeRecord = (el) ->
	group = $(el).parents('.group').first().attr 'id', 'removeRecord'
	if group.data 'id'
		ask "Удалить запись?",
			ok:
				html: "Удалить"
				class: "red"
			action: ->
				data = $('#removeRecord').data()
				db.destroy data.model, data.id, -> $('#removeRecord').remove()
			cancel: -> $('#removeRecord').attr 'id', ''
	else group.remove()

# Сортировать по

@order =
	open: (el) ->
		$(el).next().toggleClass 'active'
	pick: (el) ->
		el = $ el
		if el.hasClass 'icon-arrow-down5'
			where = 'down'
			order = el.next()
		else
			where = 'up'
			order = el.prev()
		column = order.data 'column'
		column += ' DESC' if where is 'up'
		name = order.html()
		el.parents('div').first().removeClass('active').prev().find('b').html name + " <i class='icon-arrow-#{where}5'></i>"
		template = app.index[param.model]
		rec = model: param.model
		rec.limit = template.pagination if template.pagination
		rec.select = template.select if template.select
		rec.belongs_to = template.belongs_to if template.belongs_to
		rec.has_many = template.has_many if template.has_many
		rec.ids = template.ids if template.ids
		rec.order = column
		db.get [rec], ->
			ret = ''
			for rec in db.select rec
				window.rec = rec
				ret += record()
			$('#records').html ret
			if template.pagination
				$(window).scrollTop 0
				paginator.ready = [1]
				paginator.order = column
				paginator.page = 1
				paginator.pages.find('.active').removeClass 'active'
				paginator.pages.find('div').eq(1).addClass 'active'

# Фильтр

@filter =
	open: ->
		wrap = $ "#where"
		if wrap.css('display') is 'none'
			$('#records').animate 'padding-top': 129, 300
			wrap.slideDown 300
		else
			wrap.slideUp 300
			$('#records').animate 'padding-top': 54, 300
	change: (el) ->
		where = []
		$(el).find("[type='text']").each ->
			i = $ @
			val = i.val()
			if val isnt ''
				if @name is 'sql'
					where.push val 
				else
					where.push @name + ' ' + switch i.data 'cb'
						when 'begin'
							"regexp \"^#{val}\""
						else
							val
		where = where.join ' AND '
		if !window.filter_loading
			window.filter_loading = true
			template = app.index[param.model]
			window.tmp = model: param.model
			tmp.limit = template.pagination if template.pagination
			tmp.select = template.select if template.select
			tmp.belongs_to = template.belongs_to if template.belongs_to
			tmp.has_many = template.has_many if template.has_many
			tmp.ids = template.ids if template.ids
			tmp.count = true if template.pagination
			tmp.order = template.order or 'id'
			tmp.where = where
			db.get [tmp], ->
				recs = db.select window.tmp
				if recs[0]
					ret = ''
					for rec in recs
						window.rec = rec
						ret += record()
					$('#records').html ret
					template = app.index[param.model]
					if template.pagination
						$(window).scrollTop 0
						paginator.ready = [1]
						paginator.order = template.order or 'id'
						paginator.page = 1
						pages = "<div class='prev' onclick='paginator.prev()'><i class='icon-arrow-left'></i></div><div class='active' onclick='paginator.go(this)'>1</div>"
						divide = db.count(window.tmp) / template.pagination
						pages += "<div onclick='paginator.go(this)'>#{page}</div>" for page in [2..1 + Math.floor divide] if divide >= 1
						paginator.pages.html pages + "<div class='next' onclick='paginator.next()'><i class='icon-arrow-right2'></i></div>"
				window.filter_loading = false
			, -> window.filter_loading = false
		event.preventDefault()

# Tab

@openTab = (el) ->
	el = $ el
	nav = el.parent()
	nav.find('.active').removeClass 'active'
	tabs = nav.next()
	tabs.find('> .active').removeClass 'active'
	tabs.find('> div').eq(el.addClass('active').index()).addClass 'active'

@tab =
	gen: (tabs) ->
		ret = "<div class='nav-tabs'>"
		active = true
		for k of tabs
			ret += "<p onclick='openTab(this)' class='#{if active then active = false; 'active ' else ''}capitalize'>#{k}</p>"
		ret += "</div><div class='tabs'>"
		active = true
		for k, v of tabs
			ret += "<div#{if active then active = false; " class='active'" else ''}>"
			ret += v()
			ret += "</div>"
		ret += "</div>"
		ret

# Картинка в редакторе

@editorimage =
	add: (cb) ->
		@cb = cb
		dark.open 'image'
	open: (input) ->
		if input.files
			$input = $ input
			label = $input.parent()
			controls = label.parent()
			controls.find('.hidden').removeClass 'hidden'
			preview = controls.next()
			reader = new FileReader()
			reader.onload = (e) ->
				preview.append "<a href='#{e.target.result}' data-lightbox='product'><img src='#{e.target.result}'></a>"
			reader.readAsDataURL input.files[0]
			label.addClass 'hidden'
	remove: (el) ->
		controls = $(el).parent()
		controls.find('> *').toggleClass 'hidden'
		input = controls.find 'input'
		input.replaceWith(input = input.clone true)
		controls.next().html ""
	upload: (el) ->
		formData = new FormData()
		formData.append "image", $(el).parent().find('input')[0].files[0]
		$.ajax
			url: "/admin/editorimage"
			data: formData
			type: 'POST'
			contentType: false
			processData: false
			dataType: "json"
			success: (url) ->
				notify 'Изображение загружено', 'green'
				dark.close()
				editorimage.cb url
	link: (el) ->
		dark.close()
		editorimage.cb $(el).parent().next().find('input').val()