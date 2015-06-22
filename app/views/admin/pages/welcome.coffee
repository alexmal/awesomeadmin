app.addRoute 'welcome', ->
	$('#welcome-style', app.yield).after "<form id='welcome-popup' onsubmit='return loginSubmit(this)'>
			<h2>Вход в панель</h2>
			<div class='main'>
				<div class='inputs'>
					<label><input type='email' name='user[email]' placeholder='E-mail' autofocus='true'><i class='icon-user3'></i></label>
					<label><input type='password' name='user[password]' placeholder='Пароль'><i class='icon-lock'></i></label>
				</div>
				<div>
					<label class='checkbox' style='padding-left: 28px; float: left'>
						<div style='left: 0'>
							<input type='checkbox' name='user[remember_me]' onchange='checkboxChange(this)'>
							<div class='ripple-out'></div>
						</div>Запомнить меня
					</label>
					<a href='#' style='float: right'>Восстановить пароль</a>
				</div>
				<label class='btn blue'><span>Войти<input type='submit' style='display: none'></span></label>
			</div>
		</form>"
	window.loginSubmit = (form) ->
		$.ajax
			type: "POST"
			url: '/admin/welcome'
			data: $(form).serialize()
			success: (d) ->
				window.me = d.me
				window.authenticity_token = d.authenticity_token
				$("[name='csrf-token']").attr 'content', authenticity_token
				menu.html me.role
				app.go app.pathname = window.location.pathname
				notify "Добро пожаловать, #{me.email.split('@')[0]}!"
			error: (d) ->
				notify 'Неверный e-mail или пароль',  class: 'red'
			dataType: 'json'
		false