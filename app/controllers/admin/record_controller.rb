class Admin::RecordController < Admin::AdminController

	def index
		p = Admin::Data[:index][params[:model].to_sym] || {}
		return rend(data: 'permission denied') if cant?(:get, params[:model]) or forbidden(p)
		rend data: {params[:model] => get_records(params[:model], (p))}
	end

	def new
		p = Admin::Data[:new][params[:model].to_sym] || {}
		return rend(data: 'permission denied') if cant? :create, params[:model]
		data = {}
		if p[:id]
			if p[:id].is_a? Symbol
				s = p[:id].to_s
				if params[s + '_id']
					return rend(data: 'permission denied') if cant? :get, s
					data[p[:id]] = {record: s.classify.constantize.find(params[s + '_id'])}
				end
			elsif p[:id].is_a? Array
				for id in p[:id]
					s = id.to_s
					if params[s + '_id']
						return rend(data: 'permission denied') if cant? :get, s
						data[id] = {record: s.classify.constantize.find(params[s + '_id'])}
					end
				end
			end
		end
		if p[:get]
			for k, v in p[:get]
				return rend(data: 'permission denied') if cant?(:get, k) or forbidden(v)
				data[k] = get_records k.to_s, v
			end	
		end
		rend data: data
	end

	def edit
		p = Admin::Data[:edit][params[:model].to_sym] || {}
		return rend(data: 'permission denied') if cant? :update, params[:model]
		model = params[:model].classify.constantize
		rec = model.find(params[:id])
		ret = {}
		if p[:ids]
			ret[:ids] = {}
			if p[:ids].is_a? Array
				for id in p[:ids]
					ret[:ids][id] = rec.send(id.to_s + '_ids')
				end
			else
				ret[:ids][p[:ids]] = rec.send(p[:ids].to_s + '_ids')
			end
		end
		if p[:belongs_to]
			ret[:belongs_to] = {}
			if p[:belongs_to].is_a? Array
				for bt in p[:belongs_to]
					return rend(data: 'permission denied') if cant? :get, bt.to_s
					ret[:belongs_to][bt] = rec.send(bt)
				end
			else
				return rend(data: 'permission denied') if cant? :get, p[:belongs_to].to_s
				ret[:belongs_to][p[:belongs_to]] = rec.send(p[:belongs_to])
			end
		end
		if p[:has_many]
			ret[:has_many] = {}
			if p[:has_many].is_a? Array
				for hm in p[:has_many]
					if hm.is_a? Symbol
						return rend(data: 'permission denied') if cant? :get, hm.to_s
						ret[:has_many][hm] = rec.send(hm.to_s.pluralize)
					else
						return rend(data: 'permission denied') if cant?(:get, hm[:model].to_s) or forbidden(hm)
						ret[:has_many][hm[:model]] = fill_recs(rec.send(hm[:model].to_s.pluralize), hm)
					end
				end
			elsif p[:has_many].is_a? Symbol
				return rend(data: 'permission denied') if cant? :get, p[:has_many].to_s
				ret[:has_many][p[:has_many]] = rec.send(p[:has_many].to_s.pluralize)
			else
				return rend(data: 'permission denied') if cant?(:get, p[:has_many][:model].to_s) or forbidden(p[:has_many])
				ret[:has_many][p[:has_many][:model]] = fill_recs(rec.send(p[:has_many][:model].to_s.pluralize), p[:has_many])
			end
		end
		ret[:record] = rec
		data = {params[:model] => ret}
		if p[:get]
			for k, v in p[:get]
				return rend(data: 'permission denied') if cant?(:get, k) or forbidden(v)
				data[k] = get_records k.to_s, v
			end	
		end
		rend data: data
	end

	def change
		for i, change in params[:change]
			return rend(data: 'permission denied') if cant? :update, change[:model]
			model = change[:model].classify.constantize
			if change[:find]
				records = model.where(id: change[:find])
			end
			update = {}
			if change[:update]
				update = change.require(:update).permit!
			else
				update = {}
			end
			if change[:clear_ids]
				empty = change.require(:empty)
				if empty.is_a? Array
					for f in empty
						update[f + '_ids'] = []
					end
				else
					update[empty + '_ids'] = []
				end
			end
			r.update_all update
			log = {model: params[:model], action: :update}
			list = Admin::UserLog[current_user.role.to_sym]
			if list and (list == true or (list[:all] and list[:all].include? log[:model]) or (list[log[:action]] and list[log[:action]].include? log[:model]))
				records.each do |r|
					log[:record_id] = r.id
					current_user.user_logs.create log
				end
			end
		end
		rend
	end

	def copy
		@data = {}
		def getRecs model, p, recs, parent
			return false if cant? :create, model
			p = {} if p == 'true'
			records = []
			for r in recs
				dup = r.dup
				if p[:set]
					for k, v in p[:set]
						dup[k] = v
					end
				end
				if parent
					dup[parent[:model] + '_id'] = parent[:id]
				end
				dup.save
				user_log model: model, record_id: dup.id, action: :create
				if p[:has_many]
					for sub_model, hash in p[:has_many]
						return false unless getRecs(sub_model, hash, r.send(sub_model.pluralize), {model: model, id: dup.id})
					end
				end
				records << dup
			end
			@data[model] = {records: records}
			if p[:has_many]
				@data[model][:ids] = {}
				for sub_model, hash in p[:has_many]
					@data[model][:ids][sub_model] = records.map {|r| r.send(sub_model + '_ids')}
				end
			end
			true
		end
		for model, hash in params[:copy]
			return rend(data: 'permission denied') unless getRecs(model, hash, model.classify.constantize.find(hash[:find]), false)
		end
		rend data: @data
	end

	def editorimage
		return rend(data: 'permission denied') if cant? :create, 'text_image'
		image = params[:image]
		url = ('/images/' + save_file("#{Rails.root.join('public', 'images')}/", image.original_filename, image))
		current_user.user_logs.create text: url, action: :text_image if Admin::UserLog[current_user.role.to_sym][:text_image]
		rend data: url
	end

	def sort_with_parent
		name = params[:model]
		return rend(data: 'permission denied') if cant? :update, name
		parent_id = params[:parent_id]
		parent_id = nil if parent_id == 'nil'
		model = name.classify.constantize
		if Admin::UserLog[current_user.role.to_sym][:sort]
			params[:ids].each do |id|
				current_user.user_logs.create model: params[:model], record_id: id, action: :sort
			end
		end
		params[:ids].each_with_index do |id, index|
			model.find(id).update position: index+1, "#{name}_id" => parent_id
		end
		render :nothing => true
	end

	def sort_all
		return rend(data: 'permission denied') if cant? :update, params[:model]
		model = params[:model].classify.constantize
		if Admin::UserLog[current_user.role.to_sym][:sort]
			params[:ids].each do |id|
				current_user.user_logs.create model: params[:model], record_id: id, action: :sort
			end
		end
		params[:ids].each_with_index do |id, index|
			model.find(id).update position: index+1
		end		
		render nothing: true
	end

private

	def get_records model_name, p
		model = model_name.classify.constantize
		recs = model.all
		ret = {}
		if p[:order]
			recs = recs.order(p[:order])
			ret[:order] = p[:order]
		end
		if p[:where]
			recs = recs.where(p[:where])
			ret[:where] = p[:where]
		end
		if p[:count]
			ret[:count] = recs.count
		end
		if p[:select]
			recs = recs.select(p[:select] << :id)
			ret[:select] = p[:select]
		end
		if p[:offset]
			recs = recs.offset(p[:offset])
			ret[:offset] = p[:offset]
		end
		if p[:limit]
			recs = recs.limit(p[:limit])
			ret[:limit] = p[:limit]
		end
		fill = fill_recs recs, p
		ret[:ids] = fill[:ids] if p[:ids]
		ret[:belongs_to] = fill[:belongs_to] if p[:belongs_to]
		ret[:has_many] = fill[:has_many] if p[:has_many]
		ret[:records] = recs
		ret
	end

	def fill_recs recs, p
		ret = {records: recs}
		if p[:ids]
			ret[:ids] = {}
			if p[:ids].is_a? Symbol
				ret[:ids][p[:ids]] = recs.map {|r| r.send(p[:ids].to_s + '_ids')}
			else
				for id in p[:ids]
					ret[:ids][id] = recs.map {|r| r.send(id.to_s + '_ids')}
				end
			end
		end
		if p[:belongs_to]
			ret[:belongs_to] = {}
			if p[:belongs_to].is_a? Symbol
				ret[:belongs_to][p[:belongs_to]] = recs.map{|r| r.send(p[:belongs_to])}
			elsif p[:belongs_to].is_a? Array
				for bt in p[:belongs_to]
					ret[:belongs_to][bt] = recs.map {|r| r.send(bt)}
				end
			end
		end
		if p[:has_many]
			ret[:has_many] = {}
			if p[:has_many].is_a? Symbol
				ret[:has_many][p[:has_many]] = recs.map{|r| r.send(p[:has_many].to_s.pluralize)}
			elsif p[:has_many].is_a? Array
				for hm in p[:has_many]
					ret[:has_many][hm] = recs.map {|r| r.send(hm.to_s.pluralize)}
				end
			end
		end
		ret
	end


	def forbidden p
		ret = false
		if p[:belongs_to]
			if p[:belongs_to].is_a? Symbol
				ret = cant? :get, p[:belongs_to].to_s
				return true if ret
			elsif p[:belongs_to].is_a? Array
				for bt in p[:belongs_to]
					if bt.is_a? Symbol
						ret = cant? :get, bt.to_s
						return true if ret
					else
						ret = cant? :get, bt[:model].to_s
						return true if ret
						ret = forbidden bt
						return true if ret
					end
				end
			end
		end
		if p[:has_many]
			if p[:has_many].is_a? Symbol
				ret = cant? :get, p[:has_many].to_s
				return true if ret
			elsif p[:has_many].is_a? Array
				for hm in p[:has_many]
					if hm.is_a? Symbol
						ret = cant? :get, hm.to_s
						return true if ret
					else
						ret = cant? :get, hm[:model].to_s
						return true if ret
						ret = forbidden hm
						return true if ret
					end
				end
			end
		end
		if p[:get]
			for k, v in p[:get]
				ret = cant? :get, k.to_s
				return true if ret
				ret = forbidden v
				return true if ret
			end
		end
		ret
	end

end