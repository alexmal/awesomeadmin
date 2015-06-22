Admin::Data = {
	edit: {
		product: {
			ids: :category,
			belongs_to: [:extension, :category],
			has_many: :image,
			get: {
				category: {select: [:id, :name]}
			}
		},
		size: {
			belongs_to: [:product],
			has_many: [
				{
					model: :color,
					has_many: :texture
				},
				:option
			]
		},
		color: {
			belongs_to: [:size],
			has_many: :texture
		},
		option: {
			belongs_to: :size
		},
		category: {
			belongs_to: :category,
			has_many: :image
		},
		order: {
			belongs_to: :status,
			has_many: {
				model: :order_item,
				belongs_to: :product
			}
		}
	},
	index: {
		product: {
			limit: 50,
			count: true,
			order: :position,
			select: [:name, :position],
			ids: [:size]
		},
		category: {
			select: [:name, :position, :category_id],
			order: 'position',
			ids: [:product]
		},
		order: {
			order: 'created_at DESC',
			select: [:created_at, :phone, :status_id],
			belongs_to: [:status],
			has_many: [:order_item]
		},
		packinglist: {
			ids: [:packinglistitem],
			has_many: [:packinglistitem]
		},
		user: {
			select: [:email, :role]
		},
		page: {
			select: [:url, :name]
		}
	},
	new: {
		product: {
			id: :category,
			get: {
				category: {
					all: true,
					select: [:id, :name],
					records: Category.select(:id, :name)
				}
			}
		},
		size: {
			id: :product
		},
		color: {
			id: :size
		},
		option: {
			id: :size
		},
		category: {
			id: :category
		},
		subcategory: {
			id: :category
		},
	}
}