@paginator =
	go: (el) ->
		el = $ el
		unless el.hasClass 'active'
			paginator.page = parseInt el.html()
			if paginator.page in paginator.ready
				eq = 0
				for i in [0..paginator.page - 1]
					eq += paginator.limit if i and i + 1 in paginator.ready
				$(window).scrollTop paginator.wrap.find('> .group').eq(eq).offset().top - paginator.top + 5
				paginator.pages.find('.active').removeClass 'active'
				el.addClass 'active'
			else
				paginator.load = true
				rec = model: param.model
				rec.offset = offset = (paginator.page - 1) * paginator.limit
				rec.limit = paginator.limit
				rec.select = paginator.select if paginator.select
				rec.belongs_to = paginator.belongs_to if paginator.belongs_to
				rec.has_many = paginator.has_many if paginator.has_many
				rec.ids = paginator.ids if paginator.ids
				rec.order = paginator.order if paginator.order
				get = [rec]
				db.get get, ->
					ret = ''
					for rec in db.select rec
						window.rec = rec
						ret += record()
					eq = 0
					for i in [0..paginator.page - 1]
						eq += paginator.limit if i + 1 in paginator.ready
					rec = paginator.wrap.find('> .group').eq eq - 1
					rec.after ret
					$(window).scrollTop rec.next().offset().top - paginator.top + 5
					paginator.ready.push paginator.page
					paginator.pages.find('.active').removeClass 'active'
					el.addClass 'active'
					paginator.load = false
	prev: () ->
		if paginator.page is 1
			@go paginator.pages.find('.next').prev()[0]
		else @go paginator.pages.find('.active').prev()[0]
	next: () ->
		if paginator.page is paginator.pages.find('div').length - 2
			@go paginator.pages.find('.prev').next()[0]
		else @go paginator.pages.find('.active').next()[0]
	gen: (params) ->
		if params.limit
			@wrap = $('#records')
			@pages = $('#paginator')
			@ready = [1]
			@top = @wrap.offset().top + parseInt @wrap.css 'padding-top'
			@load = false
			@limit = params.limit
			@order = params.order or 'id'
			@where = params.where or ''
			@select = params.select or 'id'
			@belongs_to = params.belongs_to
			@has_many = params.has_many
			@ids = params.ids
			@scrollTop = $(window).scrollTop() - @top
			@page = 1
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
							load = model: param.model
							load.offset = (paginator.page - 2) * paginator.limit
							load.limit = paginator.limit
							load.select = paginator.select if paginator.select
							load.belongs_to = paginator.belongs_to if paginator.belongs_to
							load.has_many = paginator.has_many if paginator.has_many
							load.ids = paginator.ids if paginator.ids
							load.order = paginator.order
							load.where = paginator.where
							get = [load]
							before = prev
							db.get get, ->
								ret = ''
								for rec in db.select load
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