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
end
