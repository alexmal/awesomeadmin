class Admin::DbController < Admin::AdminController
	def get
		@data = {}
		def forbidden (p)
			ret = cant? :get, p[:model]
			if p[:belongs_to]
				for i, a in p[:belongs_to]
					ret = forbidden(a)
				end
			end
			if p[:has_many]
				for i, a in p[:has_many]
					ret = forbidden(a)
				end
			end
			ret
		end
		if params[:models]
			for i, p in params[:models]
				return rend(data: 'permission denied') if forbidden p
				@data[p[:model]] = get_records p
			end
		end
		rend data: @data
	end
	def update
		model_name = params[:model]
		return rend(data: 'permission denied') if cant? :edit, model_name
		data = {}
		model = model_name.classify.constantize
		record = model.find params[:id]
		fields = params.require(:fields).permit!
		if params[:removeImage]
			for field in params[:removeImage]
				fields[field] = ""
				path = Rails.root.join('public').to_s + record[field]
				File.delete path if File.exists? path
			end
		end
		if params[:image]
			data[:image] = {}
			for field, image in params[:image]
				fields[field] = '/images/' + save_file("#{Rails.root.join('public', 'images')}/", image.original_filename, image)
				data[:image][field] = fields[field]
			end
		end
		record.update fields
		user_log model: params[:model], record_id: params[:id], action: :update
		if params[:removeImages]
			for id in params[:removeImages]
				record.images.find(id).destroy
			end
		end
		if params[:images]
			data[:images] = []
			for image in params[:images]
				image = {url: '/images/' + save_file("#{Rails.root.join('public', 'images')}/", image.original_filename, image)}
				image = record.images.create image
				data[:images] << image
			end
		end
		rend data: data
	end
	def create
		model_name = params[:model]
		return rend(data: 'permission denied') if cant? :create, model_name
		data = {}
		model = model_name.classify.constantize
		fields = params.require(:fields).permit!
		if params[:image]
			data[:image] = {}
			for field, image in params[:image]
				fields[field] = '/images/' + save_file("#{Rails.root.join('public', 'images')}/", image.original_filename, image)
				data[:image][field] = fields[field]
			end
		end
		record = model.create fields
		user_log model: model_name, record_id: record.id, action: :create
		data[:id] = record.id
		if params[:images]
			data[:images] = []
			for image in params[:images]
				image = {url: '/images/' + save_file("#{Rails.root.join('public', 'images')}/", image.original_filename, image)}
				image = record.images.create image
				data[:images] << image
			end
		end
		rend data: data
	end
	def destroy
		return rend(data: 'permission denied') if cant? :destroy, params[:model]
		params[:model].classify.constantize.find(params[:id]).destroy
		user_log model: params[:model], record_id: params[:id], action: :destroy
		rend
	end
private
	def get_records p
		name = p[:model]
		model = name.classify.constantize
		ret = {}
		if p[:find]
			recs = model.where(id: p[:find])
		else
			if p[:where]
				recs = model.where(p[:where])
			else
				recs = model.all
			end
			if p[:order]
				recs = recs.order(p[:order])
			end
			if p[:offset]
				recs = recs.offset(p[:offset])
			end
			if p[:count]
				ret[:count] = recs.count
			end
			if p[:limit]
				recs = recs.limit(p[:limit])
			end
		end
		if p[:select]
			recs = recs.select(p[:select] << :id)
		end
		if p[:ids]
			recs = recs.map do |r|
				ids_ret = r.as_json
				for id in p[:ids]
					ids_ret[id + '_ids'] = r.send(id + '_ids')
				end
				ids_ret
			end
		end
		ret[:records] = recs
		if p[:belongs_to]
			ret[:belongs_to] = {}
			for i, a in p[:belongs_to]
				ids = recs.map{|r| r[a[:model] + '_id']}.compact
				if a[:find]
					a[:find] += ids
				else
					a[:find] = ids
				end
				ret[:belongs_to][a[:model]] = get_records a
			end
		end
		if p[:has_many]
			ret[:has_many] = {}
			for i, a in p[:has_many]
				ids = recs.map{|r| r[a[:model] + '_ids']}.reduce(:+)
				if a[:find]
					a[:find] += ids
				else
					a[:find] = ids
				end
				ret[:has_many][a[:model]] = get_records a
			end
		end
		ret
	end
end