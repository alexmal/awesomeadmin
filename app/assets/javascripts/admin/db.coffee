@db =
	init: (array) ->
		for a in array
			@[a] =
				records: {}
				ready:
					find:
						ids: []
						records: []
						select: []
					where:
						id:
							'':
								ids: []
								records:
									all: false
									positions: []
								select: []
	collect: (hash) ->
		for n, p of hash
			model = @[n]
			r = model.ready
			if p.record
				if p.belongs_to
					for k, v of p.belongs_to
						if v
							if v.record is undefined
								v = record: v
							p.belongs_to[k] = v
						else
							delete p.belongs_to[k]
					@collect p.belongs_to
				if p.has_many
					p.ids ?= {}
					for k, v of p.has_many
						if v.length is 0
							delete p.has_many[k]
						else
							p.has_many[k] = records: v if v[0]
							hm_ids = p.has_many[k].records.map (rec) -> rec.id
							if p.ids[k]
								p.ids[k] = p.ids[k].concat hm_ids
							else p.ids[k] = hm_ids
							if p.has_many[k].records[0][n + '_id']
								p.has_many[k].where ?= {}
								p.has_many[k].where[n + '_id'] = p.record.id
					@collect p.has_many
				if p.ids
					for k, v of p.ids
						p.record[k + '_ids'] = v
					pids = []
					pids.push n for n of p.ids
					r.find.ids.push key: pids, records: [p.record.id]
				if p.select
					r.find.select.push key: p.select, records: p.record.id
				else
					r.find.records = [p.record.id]
				model.records[p.record.id] = p.record
			else if p.records.length
				ids = p.records.map (r) -> r.id
				if p.order
					p.order = [p.order] if typeof p.order is 'string'
					p.order = p.order.join()
					order = p.order
					r.where[order] =
						'':
							ids: []
							records:
								all: false
								positions: []
							select: []
				else order = 'id'
				if p.where
					if typeof p.where is 'object'
						where = []
						for k, v of p.where
							where.push k + ' = ' + v
						where = where.sort().join(' AND ')
					else where = p.where
					r.where[order][where] =
						ids: []
						records:
							all: false
							positions: []
						select: []
				else where = ''
				if p.belongs_to
					for k, v of p.belongs_to
						unless v.records
							v = records: v
						recs = []
						for rec in v.records
							if rec
								recs.push rec
						v.records = recs
						p.belongs_to[k] = v
					@collect p.belongs_to
				if p.has_many
					p.ids ?= {}
					for k, v of p.has_many
						if v[0]
							p.has_many[k] = records: v.reduce (a, b) -> a.concat b
							hm_ids = v.map (arr) -> arr.map (rec) -> rec.id
						else
							if v.records.length
								p.has_many[k].records = v.records.reduce (a, b) -> a.concat b
								hm_ids = v.records.map (arr) -> arr.map (rec) -> rec.id
						if hm_ids
							if p.ids[k]
								p.ids[k] = p.ids[k].concat hm_ids
							else p.ids[k] = hm_ids
					@collect p.has_many
				if p.ids
					for rec, i in p.records
						for k, v of p.ids
							rec[k + '_ids'] = v[i]
					pids = []
					pids.push n for n of p.ids
					r.find.ids.push key: pids, records: ids
					push = key: pids, records: {all: false, positions: []}
					push.records.all = true if !p.offset and !p.limit
					p.offset ?= 0
					if p.limit
						limit = p.offset + p.limit - 1
					else
						push.records.offset = p.offset
						limit = p.records.length - 1
					for i in [p.offset..limit]
						rec = p.records[i - p.offset]
						if rec
							push.records.positions[i] = rec.id
						else push.records.positions[i] = 0
					r.where[order][where].ids.push push
				if p.select
					r.find.select.push key: p.select, records: ids
					push = key: p.select, records: {all: false, positions: []}
					push.records.all = true if !p.offset and !p.limit
					p.offset ?= 0
					if p.limit
						limit = p.offset + p.limit - 1
					else
						push.records.offset = p.offset
						limit = p.records.length - 1
					for i in [p.offset..limit]
						rec = p.records[i - p.offset]
						if rec
							push.records.positions[i] = rec.id
						else push.records.positions[i] = 0
					r.where[order][where].select.push push
				else
					r.find.records = ids
					r.where[order][where].records.all = true if !p.offset and !p.limit
					p.offset ?= 0
					if p.limit
						limit = p.offset + p.limit - 1
					else
						r.where[order][where].records.offset = p.offset
						limit = p.records.length - 1
					for i in [p.offset..limit]
						rec = p.records[i - p.offset]
						if rec
							r.where[order][where].records.positions[i] = rec.id
						else r.where[order][where].records.positions[i] = 0
				r.where[order][where].count = p.count if p.count
				model.records[rec.id] = rec for rec in p.records
	_get_ready: (r, p) ->
		if p.order
			p.order = [p.order] if typeof p.order is 'string'
			order_array = p.order
			p.order = p.order.join()
			order = p.order
			unless r.where[order]
				r.where[order] =
					'':
						ids: []
						records:
							all: false
							positions: []
						select: []
		else order = 'id'
		if p.where
			if typeof p.where is 'object'
				where = []
				for k, v of p.where
					where.push k + ' = ' + v
				where = where.sort().join(' AND ')
				p.where = where
			else where = p.where
			unless r.where[order][where]
				r.where[order][where] =
					ids: []
					records:
						all: false
						positions: []
					select: []
		else where = ''
		r.where[order][where]
	_fill_where: (records, p, arr) ->
		records.all = true if !p.offset and !p.limit
		p.offset ?= 0
		if p.limit
			limit = p.offset + p.limit - 1
		else limit = arr.length - 1
		for i in [p.offset..limit]
			rec = arr[i - p.offset]
			if rec
				records.positions[i] = rec.id
			else records.positions[i] = 0
	_find_in_ready: (ready_hash, find_array) ->
		records = false
		for a in ready_hash
			ok = true
			for b in find_array
				unless b in a.key
					ok = false
					break
			if ok
				records = a.records
				break
		records
	get: (params, cb, error) ->
		params = [params] unless params[0]
		string_to_array = (p) ->
			p.find = [p.find] if p.find and typeof p.find is 'number'
			p.ids = [p.ids] if p.ids and typeof p.ids is 'string'
			p.select = [p.select] if p.select and typeof p.select is 'string'
			p.order = [p.order] if p.order and typeof p.order is 'string'
			if p.belongs_to
				if typeof p.belongs_to is 'string'
					p.belongs_to = [model: p.belongs_to]
				else
					p.belongs_to = [p.belongs_to] unless p.belongs_to[0]
					for bt, i in p.belongs_to
						if typeof bt is 'string'
							p.belongs_to[i] = model: bt
				string_to_array bt for bt in p.belongs_to
			if p.has_many
				p.ids ?= []
				if typeof p.has_many is 'string'
					p.has_many = [model: p.has_many]
				else
					p.has_many = [p.has_many] unless p.has_many[0]
					for hm, i in p.has_many
						if typeof hm is 'string'
							p.has_many[i] = model: hm
				for hm in p.has_many
					p.ids.push hm.model unless hm.model in p.ids
					string_to_array hm
		for p in params
			string_to_array p
		find_analizer = (records, p) ->
			load = false
			for id in p.find
				unless id in records
					load = p
					break
			load
		where_analizer = (records, p) ->
			if records.all
				false
			else
				if p.offset or p.limit
					p.offset ?= 0
					if p.limit
						ret = false
						for i in [p.offset..p.offset + p.limit - 1]
							unless records.positions[i]
								ret = p
								break
						ret
					else
						if records.offset
							if records.offset > p.offset
								p.limit = records.offset - p.offset
								records.offset = p.offset
								p
							else false
						else p
				else p
		check = (p) ->
			r = db[p.model].ready
			load = false
			if p.find
				if p.ids
					records = db._find_in_ready r.find.ids, p.ids
					if records
						load = find_analizer records, p
					else
						r.find.ids.push key: p.ids, records: []
						load = p
				unless load
					records = r.find.records
					load = find_analizer records, p if records
				if p.select and load
					records = db._find_in_ready r.find.select, p.select
					if records
						load = find_analizer records, p
					else r.find.select.push key: p.select, records: []
			else
				r = db._get_ready r, p
				if p.ids
					records = db._find_in_ready r.ids, p.ids
					if records
						load = where_analizer records, p
					else
						r.ids.push key: p.ids, records: {all: false, positions: []}
						load = p
				unless load
					records = r.records
					load = where_analizer r.records, p
				if p.select and load
					records = db._find_in_ready r.select, p.select
					if records
						load = where_analizer records, p
					else r.select.push key: p.select, records: {all: false, positions: []}
			if !load
				if p.belongs_to or p.has_many
					if p.find
						recs = db.find p.model, records
					else
						recs = db.select p
					if p.belongs_to
						for bt in p.belongs_to
							ids = []
							for r in recs
								id = r[bt.model + '_id']
								ids.push id if id
							if ids.length
								bt.find = ids
								bt = check bt, bt.model
								load_params.push bt if bt
					if p.has_many
						for hm in p.has_many
							ids = []
							for r in recs
								id = r[hm.model + '_ids']
								ids = ids.concat id
							if ids.length
								hm.find = ids
								hm = check hm, hm.model
								load_params.push hm if hm
			load
		send_params = {}
		load_params = []
		for p, i in params
			params[i] = check p
			load_params.push params[i] if params[i]
		if load_params.length
			$.ajax type: "POST", url: '/admin/db/get', data: {models: load_params}, dataType: 'json', success: (res) ->
				recursion_save = (p, res) ->
					db_records = db[p.model].records
					r = db[p.model].ready
					res_model = res[p.model]
					res_records = res_model.records
					if p.ids
						ids = db._find_in_ready r.find.ids, p.ids
						unless ids
							ids = []
							r.find.ids.push key: p.ids, records: ids
					if p.select
						select = db._find_in_ready r.find.select, p.select
						unless select
							select = []
							r.find.select.push key: p.select, records: select
					if p.ids and p.select
						for rec in res_records
							ids.push rec.id unless rec.id in ids
							select.push rec.id unless rec.id in select
							if db_records[rec.id]
								$.extend true, db_records[rec.id], rec
							else db_records[rec.id] = rec
						unless p.find
							r = db._get_ready r, p
							db._fill_where db._find_in_ready(r.ids, p.ids), p, res_records
							db._fill_where db._find_in_ready(r.select, p.select), p, res_records
					else if p.ids
						for rec in res_records
							ids.push rec.id unless rec.id in ids
							r.find.records.push rec.id
							if db_records[rec.id]
								$.extend true, db_records[rec.id], rec
							else db_records[rec.id] = rec
						unless p.find
							r = db._get_ready r, p
							db._fill_where db._find_in_ready(r.ids, p.ids), p, res_records
							db._fill_where r.records, p, res_records
					else if p.select
						for rec in res_records
							select.push rec.id unless rec.id in select
							if db_records[rec.id]
								$.extend true, db_records[rec.id], rec
							else db_records[rec.id] = rec
						unless p.find
							r = db._get_ready r, p
							db._fill_where db._find_in_ready(r.select, p.select), p, res_records
					else
						for rec in res_records
							r.find.records.push rec.id
							if db_records[rec.id]
								$.extend true, db_records[rec.id], rec
							else db_records[rec.id] = rec
						unless p.find
							r = db._get_ready r, p
							db._fill_where r.records, p, res_records
					if res_model.count
						r.count = res_model.count
					if p.belongs_to
						for bt in p.belongs_to
							ids = []
							ids.push rec[bt.model + '_id'] for rec in res_records
							bt.find = ids
							recursion_save bt, res_model.belongs_to
					if p.has_many
						for hm in p.has_many
							if res_records.length
								hm.find = res_records.map((r) -> r[hm.model + '_ids']).reduce((a, b) -> a.concat b)
								recursion_save hm, res_model.has_many
				for p, i in load_params
					recursion_save p, res
				cb() if cb
			, error: -> error() if error
		else
			cb() if cb
	all: (model) ->
		ret = []
		ret.push rec for id, rec of db[model].records
		ret
	find: (model, find) ->
		return [] if !find
		find = [find] if typeof find is 'number'
		return [] if !find.length
		ret = []
		for f in find
			ret.push @[model].records[f]
		ret
	find_one: (model, find) -> @find(model, find)[0]
	where: (model, params) ->
		ret = []
		for id, rec of @[model].records
			push = true
			for k, v of params
				push = false if rec[k] != v
			ret.push rec if push
		ret
	images: (model, id) -> db.where "image", imageable_type: model.classify(), imageable_id: id
	destroy: (model, id, cb) ->
		$.post "/admin/model/#{model}/destroy/#{id}", {}, (res) ->
			if res is 'permission denied'
				notify 'Доступ запрещен', 'red'
			else
				rec = db[model].records[id]
				for k, v of rec
					if k[-3..-1] is '_id'
						ids = db[k[0..-4]].records[v][model + '_ids']
						ids.splice ids.indexOf(id), 1
				h.records.splice h.records.indexOf(id), 1 for h in db[model].ready.find.ids
				db[model].ready.find.records.splice db[model].ready.find.records.indexOf(id)
				h.records.splice h.records.indexOf(id), 1 for h in db[model].ready.find.select
				for order, order_hash of db[model].ready.where
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
				delete db[model].records[id]
				notify 'Запись удалена', 'green'
				cb() if cb
		, 'json'
	create_one: (model, fields, cb) ->
		$.post "/admin/db/create_one", model: model, fields: fields, cb, 'json'
	update_one: (model, id, fields, cb) ->
		$.post "/admin/db/update_one", id: id, model: model, fields: fields, cb, 'json'
	select: (p) ->
		ids = []
		r = @_get_ready @[p.model].ready, p
		if p.ids
			p.ids = [p.ids] if typeof p.ids is 'string'
			records = @_find_in_ready(r.ids, p.ids).positions
		else if p.select
			records = @_find_in_ready(r.select, p.select).positions
		else records = r.records.positions
		p.offset ?= 0
		if p.limit
			limit = p.offset + p.limit - 1
		else limit = records.length - 1
		for i in [p.offset..limit]
			rec = records[i]
			ids.push rec if rec
		@find p.model, ids
	count: (p) -> @_get_ready(@[p.model].ready, p).count