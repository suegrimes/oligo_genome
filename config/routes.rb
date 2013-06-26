OligoGenome::Application.routes.draw do
  match '/' => 'oligo_designs#welcome'
  match '/signup' => 'users#new', :as => :signup
  match '/forgot' => 'users#forgot', :as => :forgot
  match 'reset/:reset_code' => 'users#reset', :as => :reset
  match '/login' => 'sessions#new', :as => :login
  match '/logout' => 'sessions#destroy', :as => :logout
  resources :users
  resource :session
  match '/faq_statistics' => 'help#statistics', :as => :faq_statistics
  match '/faq_technology' => 'help#technology', :as => :faq_technology
  match '/faq_protocol' => 'help#protocol', :as => :faq_protocol
  match '/faq_annotations' => 'help#annotations', :as => :faq_annotations
  match '/faq_ucsc_view' => 'help#ucsc_view', :as => :faq_ucsc_view
  match '/faq_contact' => 'help#contact', :as => :faq_contact
  resources :oligo_designs
  resources :design_queries, :only => :index
  match 'designquery' => 'design_queries#new_query', :as => :designquery
  match 'showdepth' => 'design_queries#show_depth', :as => :showdepth
  match 'export' => 'design_queries#export', :as => :export
  match 'zip_list' => 'downloads#index', :as => :zip_list
  match 'zip_download' => 'downloads#zip_download', :as => :zip_download
  match 'notimplemented' => 'dummy#notimplemented', :as => :notimplemented
  match '/:controller(/:action(/:id))'
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
