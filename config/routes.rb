Sapphire::Application.routes.draw do

  devise_for :users

  resources :projects do 
    get :search
    get :s, :action => :search_results
    get :upload
    post :upload, :action => :process_upload
    get :add_user
    put :remove_user
    post :associate_user
    post :publish
    resources :collections do
      get :upload
      post :publish
      post :upload, :controller => :projects, :action => :process_upload
      get :export
      get :export_with_files
      get :cv
      get :edit_cv
      resources :items do
        put :restore
      end
      resources :schemas do
        put :restore
      end
    end
  end
  resources :seafiles do
    collection do
      post :set_token
      get :directory_listing
    end
  end
  root :to => 'projects#index'

end
