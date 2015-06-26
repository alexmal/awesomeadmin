@validate = (el) ->
	el = $ el
	params = msg: [], el: el, val: el.val(), active: false, div: el.next(), v: el.data('validate'), cb: (params) ->
		if params.v.presence
			if params.val is ''
				params.active = true
				params.msg.push "Поле не должно быть пустым"
		if params.v.email
			unless /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i.test params.val
				params.active = true
				params.msg.push "E-mail введён неверно"
		if params.v.minLength
			if params.val.length < params.v.minLength
				params.active = true
				if params.v.minLength < 2
					end = ''
				else if params.v.minLength < 5
					end = 'а'
				else
					end = 'ов'
				params.msg.push "Значение должно содержать минимум #{v.minLength} знак#{end}"
		if params.v.equal
			items = $ "[data-validate-equal='#{params.v.equal}']"
			other = []
			for item in items
				if item.value is ''
					other = []
					break
				if item.name isnt params.el.attr 'name'
					other.push item
			equal = true
			for item in other
				if item.value isnt params.val
					equal = false
					break
			if !equal
				params.active = true
				params.msg.push params.v.equal_msg
			params.el.data 'currentEqualValidate', true
			for item in other
				unless $(item).data 'currentEqualValidate'
					validate item
			params.el.data 'currentEqualValidate', false
		if params.v.custom
			res = eval(params.v.custom) params.val
			if !res.ok
				params.active = true
				params.msg.push res.msg
		if params.active
			params.div.addClass('active').find('p').html params.msg.join '. '
		else
			params.div.removeClass 'active'
	, uniq_cb: (params) ->
		if params.v
			if params.v.uniq and params.val isnt params.el.data 'validateWas'
				post 'checkuniq', model: param.model, field: params.el.attr('name'), val: params.val, (nil) ->
					if nil isnt true
						params.active = true
						params.msg.push "Такое значение уже есть"
					params.cb params
			else
				params.cb params
	if params.v.async
		window[params.v.async] params
	else params.uniq_cb params