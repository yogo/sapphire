Sapphire::Application.routes.draw do

  resources :projects do 
    get :search
    post :search, :action=> :search_results
    get :upload
    post :upload, :action=>:process_upload
    resources :collections do
      get :upload
      post :upload, :controller => :projects, :action=>:process_upload
      resources :items
      resources :schemas
    end
  end

  root :to => 'projects#index'

end
