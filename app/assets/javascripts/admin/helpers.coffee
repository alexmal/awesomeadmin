@header = (name, params = {}) ->
	ret = "<div class='header'style='#{if params.absolute then " position: absolute" else ''; if params.top then "left: #{app.menu.width()}px" else ''}'>
		<div class='top'>
			<div class='name'>#{name}</div>"
	if params.where
		ret += "<div><p style='cursor: pointer' onclick='filter.open()'>Фильтр</p></div>"
	if params.order
		ret += "<div id='order'>"
		for o in params.order
			if o.active
				ret += "<p onclick='order.open(this)'>Сортировать по: "
				for k, v of o
					ret += "<b>#{v} <i class='icon-arrow-down5'></i></b>"
					break
				ret += "</p>"
		ret += "<div>"
		for o in params.order
			for k, v of o
				ret += "<p><i class='icon-arrow-down5' onclick='order.pick(this)'></i>по <span data-column='#{k}'>#{v}</span><i class='icon-arrow-up5' onclick='order.pick(this)'></i></p>"
				break
		ret += "</div></div>"
	if params.pagination
		ret += "<div id='paginator'>
				<div class='prev' onclick='paginator.prev()'><i class='icon-arrow-left'></i></div>
				<div class='active' onclick='paginator.go(this)'>1</div>"
		divide = db.count(window.rec) / params.pagination
		ret += "<div onclick='paginator.go(this)'>#{page}</div>" for page in [2..1 + Math.floor divide] if divide >= 1
		ret += "<div class='next' onclick='paginator.next()'><i class='icon-arrow-right2'></i></div>
			</div>"
	if params.btn
		ret += "<div><div onclick='#{params.btn[1]}' class='btn green'><span>#{params.btn[0]}</span></div></div>"
	if params.link
		ret += "<div><a href='#{params.link[1]}' onclick='app.aclick(this)' class='btn green'><span>#{params.link[0]}</span></a></div>"
	ret += "</div>"
	if params.where
		ret += "<div id='where-wrap'><form id='where' onsubmit='filter.change(this)' style='display: none'>"
		for w in params.where
			if w is 'all'
				ret += "<input type='text' name='sql'>"
			else
				for k, v of w
					if typeof v is 'string'
						name = v
						cb = ''
					else
						for n, t of v
							name = n
							cb = " data-cb='#{t}'"
					ret += "<p><label>#{k}:<input type='text' name='#{name}'#{cb}></label></p>"
		ret += "<label class='submit btn green'><span>Применить<input type='submit'></span></label></form></div>"
	if params.group
		ret += "<div class='group-header'><div>"
		for h in params.group
			if typeof h is 'string'
				ret += "<p>#{h}</p>"
			else
				for n, w of h
					if w[0] is 'p'
						ret += "<p style='padding: 0 #{w[1..-1]}px'>#{n}</p>"
					else ret += "<p style='width: #{if w is 'min' then '1%' else if w is 'max' then '100%' else w}'>#{n}</p>"
		ret += "</div></div>"
	ret + "</div>"

@group = (html, params = {}) ->
	ret = "<div class='group' data-model='#{params.model or window.model}'#{if window.rec then " data-id='#{window.rec.id}'" else ''}><table>#{html}</table>"
	if params.relations
		subrecs = []
		if params.relations.has_self_open
			where = {}
			where[param.model + '_id'] = window.rec.id
			subrecs = db.where param.model, where
		ret += "<div class='relations"
		ret += " active" if subrecs.length
		ret += "'>"
		if params.relations.close
			for k, v of params.relations.close
				ids = window.rec["#{k}_ids"] or []
				ret += "<div class='relation-wrap' data-model='#{window.model}' data-id='#{window.rec.id}' data-model-wrap='#{k}' data-ids='[#{ids.join ','}]'#{if v.data then " data-data='#{JSON.stringify v.data}'" else ''}>
					<div class='relation-header'>
						<div><div class='row'>#{v.header}</div></div>"
				if v.group
					ret += "<div><div class='group-header'><div>"
					for h in v.group
						if typeof h is 'string'
							ret += "<p>#{h}</p>"
						else
							for n, w of h
								if w[0] is 'p'
									ret += "<p style='padding: 0 #{w[1..-1]}px'>#{n}</p>"
								else ret += "<p style='width: #{if w is 'min' then '1%' else if w is 'max' then '100%' else w}'>#{n}</p>"
					ret += "</div></div></div>"
				ret += "</div></div>"
		if subrecs.length
			ret += "<div class='relation-wrap start' data-model-wrap='#{param.model}'>"
			ret += each_record subrecs, params.relations.has_self_open
			ret += "</div>"
		ret += "</div>"
	ret + "</div>"

@cells = (array) -> array.map((a) -> "<tr>#{if typeof a is 'string' then a else a.join ''}</tr>").join ''

@tr = (html, attrs) ->
	ret = "<tr"
	ret += " #{k}='#{v}'" for k, v of attrs if attrs
	ret + ">#{if typeof html is 'string' then html else html.join ''}</tr>"

@td = (html, attrs) ->
	ret = "<td"
	ret += " #{k}='#{v}'" for k, v of attrs if attrs
	ret + ">#{html}</td>"

@input = (name, header, params = {}, td_attrs) ->
	if typeof  header is 'object'
		params = header
		header = false
	val = if window.rec then window.rec[name] else ''
	val = params.val_cb val if params.val_cb
	ret = "<td class='input'"
	ret += " #{k}='#{v}'" for k, v of td_attrs if td_attrs
	ret += "><label class='row'#{if params.validation then " style='position: relative'" else ''}>"
	ret += "<p>#{header}</p>" if header
	ret += "<input type='#{params.type || 'text'}' name='#{name}'"
	if params.format
		ret += " data-format='#{if typeof params.format is 'string' then params.format else JSON.stringify params.format}'"
		if val
			if window.rec and params.format is 'currency'
				val = val.toCurrency() + ' руб.'
			else if params.format.date
				val = new Date(val).toString params.format.date
		else if (params.format.not_null or params.format.decimal or params.format.date) and val is null
			val = ''
	ret += " value='#{val}'"
	onchanges = []
	if params.attrs
		for k, v of params.attrs
			if k is 'onchange'
				onchanges.push v
			else ret += " #{k}='#{v}'"
	if params.validation
		onchanges.push "validate(this)"
		ret += " data-validate-was='#{if window.rec then window.rec[name] else ''}'
			data-validate='#{JSON.stringify params.validation}'"
	ret += "#{if onchanges.length then " onchange='#{onchanges.join ';'}'" else ''}>"
	ret += "<div class='validation'><p></p></div>" if params.validation
	ret + "</label></td>"

@checkbox = (header, name, attrs) ->
	td "<div class='row'>
		<label class='checkbox'>
			<div#{if window.rec and window.rec[name] then " class='checked'" else ''}>
				<input#{if window.rec and window.rec[name] then " checked" else ''} type='checkbox' name='#{name}' onchange='checkboxChange(this)'>
				<div class='ripple-out'></div>
			</div>#{header or ''}
		</label>
	</div>", attrs

@image_wrap = (name = 'image', header = 'Добавить изображение', attrs) ->
	ret = ""
	name ?= 'image'
	if attrs
		attrs_line = ''
		attrs_line += " #{k}=\"#{v}\"" for k, v of attrs
	if window.rec and window.rec[name]
		url = window.rec[name]
		ret += "<div class='image'>
			<div class='btn red remove' onclick='window.image.removeOneImage(this, \"#{name}\", \"#{url}\")'></div>
			<a href='#{url}' data-lightbox='product'><img#{if attrs then " " + attrs_line else ''} src='#{url}'></a>
		</div>"
		hide = true
	ret + "<label#{if attrs then " data-attrs='#{attrs_line}'" else ''} class='m15 text-center#{if hide then ' hide' else ''}'>
		<div class='btn blue ib'><span>#{header || 'Добавить изображение'}</span></div>
		<input class='hide' name='image-file' onchange='window.image.upload(this)' data-field='#{name}' type='file'>
	</label>"
@image_field = (name = 'image', header = 'Добавить изображение') -> "<div class='image-form'>#{image_wrap name, header}</div>"
@image_td = (name, header) -> "<td class='image'>#{image_wrap(name, header)}</td>"
@images = (header) ->
	ret = "<div class='images-form' #{if window.rec then " data-record-id='#{window.rec.id}'" else ''}>"
	if window.rec
		images = db.images window.model.classify(), window.rec.id
		for img in images
			ret += "<div class='image' data-id='#{img.id}'>
				<div class='btn red remove' onclick='window.image.removeImage(this)'></div>
				<a href='#{img.url}' data-lightbox='product'><img src='#{img.url}'></a>
			</div>"
	ret + "</div>
		<div class='images-container'>
			<label class='text-center'><div class='btn blue ib'><span>#{if header then header else "Добавить изображение"}</span></div><input class='hide' onchange='window.image.upload(this)' type='file' name='images-file' multiple></label>
		</div>"

@btn_relation = (header, name) -> "<td class='btn green fade' style='width: 1px' onclick='relationToggle(this, \"#{name}\")'><p>#{header} (<span class='relations-count'>#{window.rec[name + '_ids'].length}</span>)</p></td>"
@relation_model = (name, model, params) ->
	params.link = ['Создать', "/admin/model/#{model}/new?#{window.model}_id=#{window.rec.id}"] if !params.link and !params.btn
	header = "<p style='width: 100%'>#{name}</p>"
	if params.link
		header += "<a class='btn green square' onclick='app.aclick(this)' href='#{params.link[1]}'><span>#{params.link[0]}</span></a>"
	if params.btn
		if params.btn is true
			params.btn = ['Добавить', "#{model}_relation_add(this, \"#{model}\")"]
			window["#{model}_relation_add"] = (el, model) ->
				window.model = model
				$(el).parents('.relation-header').after window["#{model}_relation_render"]()
		header += "<div class='btn green square' onclick='#{params.btn[1]}'><span>#{params.btn[0]}</span></div>"
	window["#{model}_relation_render"] = params.cb
	ret = header: header
	ret.data = params.data
	ret.group = params.group
	ret

@drag = -> "<td style='width: 38px' class='btn lightblue drag-handler'><i style='display: inline-block; width: 9px' class='icon-cursor'></i></td>"
@new_child_link = -> "<td style='width: 38px' class='btn green'><a onclick='app.aclick(this)' href='/admin/model/#{window.model}/new?category_id=#{window.rec.id}'><i class='icon-plus'></i></a></td>"
@edit = -> "<td style='width: 38px' class='btn orange'><a onclick='app.aclick(this)' href='/admin/model/#{window.model}/edit/#{window.rec.id}'><i class='icon-pencil3'></i></a></td>"
@destroy = -> "<td style='width: 38px' class='btn red' onclick='removeRecord(this)'><i class='icon-remove3' style='top: -1px'></i></td>"
@buttons = -> edit() + destroy()
@save = -> "<td style='width: 38px' class='btn green' onclick='groupSaveRecord(this)'><i class='icon-checkmark'></i></td>"

@habtm_checkboxes = (header, model, name, col) ->
	if window.rec
		ids = window.rec[model + '_ids']
	else
		ids = []
	ret = "<div class='panel'><p>#{header}</p><div><table class='checkboxes'>"
	recs = []
	for k, v of db[model].records
		recs.push v
	while recs.length
		row = recs.splice 0, col
		ret += "<tr>"
		for td_rec in row
			if td_rec.id in ids
				checked = true
			else checked = false
			ret += "<td>
				<div class='row'>
					<label class='checkbox'>
						<div#{if checked then " class='checked'" else ''}>
							<input#{if checked then " checked" else ''} class='habtm_checkboxes' name='habtm_checkboxes' type='checkbox' data-field='#{model + '_ids'}' value='#{td_rec.id}' onchange='checkboxChange(this)'>
							<div class='ripple-out'></div>
						</div>#{td_rec[name]}
					</label>
				</div>
			</td>"
		ret += "</tr>"
	ret + "</table></div></div>"

@show = (name, attrs, def) -> td "<p>#{window.rec[name] || def || ''}</p>", attrs
@currency = (name, attrs) -> td "<p>#{window.rec[name].toCurrency() + ' руб.'}</p>", attrs
@show_date = (name, date, attrs, def) ->
	val = window.rec[name]
	if val
		val = new Date(val).toString date
	else if def
		val = new Date(def).toString date
	td "<p>#{val}</p>", attrs

@tb = (header, model, tb, attrs) ->
	tb.style = 'width: 100%'
	tb.input = name: model + "_id"
	if window.rec
		tb.rec = db.find_one model, window.rec[model + '_id']
		tb.notModel = param.model
		tb.notId = window.rec.id
	else if app.qparam[model + '_id']
		bt_rec = db[model].records[app.qparam[model + '_id']]
		tb.rec = bt_rec if bt_rec
	td "<div class='row'><p>#{header}</p>" + treebox.gen(tb) + "</div>", attrs