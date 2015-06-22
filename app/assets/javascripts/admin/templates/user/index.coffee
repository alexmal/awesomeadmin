app.templates.index.user =
	page: (recs) ->
		title('Пользователь', ['E-mail', 'Роль':'141px', 'Действия':'min']) + records each_record recs, ->
			group tr show('email') + show('role', style: 'width: 175px') + buttons()
	select: ['email', 'role']