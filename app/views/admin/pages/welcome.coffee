app.addRoute 'welcome', ->
	$('#welcome-style', app.yield).after "<form id='welcome-popup'#{if create_admin then " style='margin-top: -169px'" else ''} onsubmit='return loginSubmit(this)'>
			<h2>#{if create_admin then 'Новый администратор' else 'Вход в панель'}</h2>
			<div class='main'>
				<div class='inputs'>
					<label><input type='email' name='user[email]' placeholder='E-mail' autofocus='true'><i class='icon-user3'></i></label>
					<label><input type='password' name='user[password]' placeholder='Пароль'><i class='icon-lock'></i></label>
					#{if create_admin then "<label><input type='password' name='user[password_confirmation]' placeholder='Подтверждение пароля'><i class='icon-lock'></i></label>" else ''}
				</div>
				<div>
					<label class='checkbox' style='padding-left: 28px; #{if !create_admin then "float: left" else ''}'>
						<div style='left: 0'>
							<input type='checkbox' name='user[remember_me]' onchange='checkboxChange(this)'>
							<div class='ripple-out'></div>
						</div>Запомнить меня
					</label>
					#{if !create_admin then "<a href='#' style='float: right'>Восстановить пароль</a>" else ''}
				</div>
				<label class='btn blue'><span>#{if create_admin then "Создать<input type='hidden' name='user[role]' value='admin'>" else "Войти"}<input type='submit' style='display: none'></span></label>
			</div>
		</form>"
	window.loginSubmit = (form) ->
		if create_admin
			url = '/admin'
		else url = '/admin/welcome'
		$.ajax
			type: "POST"
			url: url
			data: $(form).serialize()
			success: (d) ->
				window.me = d.me
				window.authenticity_token = d.authenticity_token
				$("[name='csrf-token']").attr 'content', authenticity_token
				menu.html me.role
				app.go app.pathname = window.location.pathname
				notify "Добро пожаловать, #{me.email.split('@')[0]}!", 'green'
			error: (d) ->
				notify 'Неверный e-mail или пароль', 'red'
			dataType: 'json'
		false