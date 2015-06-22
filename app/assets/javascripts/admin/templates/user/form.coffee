app.templates.form.user =
	page: ->
		ret = tr input("email", "E-mail", {validation: {presence: true, uniq: true}}, style: "width: 50%", colspan: 2) +
			input "role", "Роль", {format: not_null: true}, style: "width: 50%", colspan: 2
		if window.rec
			ret += tr input "password", "Изменить пароль", {type: 'password', validation: {custom: 'change_pass'}, val_cb: -> ''}, colspan: 2
		else
			ret += tr input('password', 'Пароль', {type: 'password', validation: {minLength: 8}}, colspan: 3) +
				input 'password_confirmation', 'Подтверждение пароля', {type: 'password', validation: {custom: 'password_confirmation'}}, colspan: 3
		title('пользователь') + form ret
	beforeSave: ->
		if window.rec
			pass = $ "[name='password']"
			if pass.val() is ''
				pass.data 'ignore', true
			else
				pass.data 'ignore', false
				conf = $("[name='password_confirmation']")
				if conf.length
					conf.val pass.val()
				else pass.after "<input type='hidden' name='password_confirmation' value='#{pass.val()}'><input type='hidden' name='confirmed_at' value='#{new Date}'>"
		else
			$("[name='password_confirmation']").after "<input type='hidden' name='confirmed_at' value='#{new Date}'>" unless $("[name='confirmed_at']").length
	functions:
		password_confirmation: (val) ->
			pass = $ "[name='password']"
			ret = ok: true, msg: 'Пароли не совпадают'
			ret.ok = false unless pass.val() is val
			ret
		change_pass: (val) ->
			ret = ok: true, msg: "Значение должно содержать минимум 8 знаков"
			ret.ok = false if val.length and val.length < 8
			ret