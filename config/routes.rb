Awesomeadmin::Engine.routes.draw do
  devise_for :users, path_names: {sign_in: 'welcome', sign_out: 'logout'}, controllers: { registrations: 'admin/registrations', sessions: 'admin/sessions' }

  match '/', to: 'admin/admin#home', via: [:get, :post]

  post 'record/copy_between_sizes', to: 'admin/record#copy_between_sizes'

  post 'db/get', to: 'admin/db#get'
  post 'db/:model/create', to: 'admin/db#create'
  post 'db/:model/update/:id', to: 'admin/db#update'
  post 'model/:model/destroy/:id', to: 'admin/db#destroy'

  match 'model/:model/new', to: 'admin/record#new', via: [:get, :post]
  match 'model/:model/edit/:id', to: 'admin/record#edit', via: [:get, :post]
  match 'model/:model', to: 'admin/record#index', via: [:get, :post]
  post 'record/change', to: 'admin/record#change'
  post 'record/copy', to: 'admin/record#copy'
  post 'record/sort_with_parent', to: 'admin/record#sort_with_parent'
  post 'record/sort_all', to: 'admin/record#sort_all'

  post 'write', to: 'admin/admin#write'
  post 'images_sort', to: 'admin/admin#images_sort'
  post 'checkuniq', to: 'admin/admin#checkuniq'
  post 'editorimage', to: 'admin/record#editorimage'
end