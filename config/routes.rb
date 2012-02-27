Sapphire::Application.routes.draw do

  devise_for :users

  resources :projects do 
    get :search
    get :s, :action=> :search_results
    get :upload
    post :upload, :action=>:process_upload
    resources :collections do
      get :upload
      post :upload, :controller => :projects, :action=>:process_upload
      resources :items do
        put :restore
        get :controlled_vocabulary_term
      end
      resources :schemas
    end
  end

  root :to => 'projects#index'

end
