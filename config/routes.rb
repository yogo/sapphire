Sapphire::Application.routes.draw do

  devise_for :users

  resources :projects do 
    get :search
    get :s, :action=> :search_results
    get :upload
    post :upload, :action=>:process_upload
    get :add_user
    post :associate_user
    post :publish
    collection do
      get :manage_controlled_vocabularies
    end
    resources :collections do
      get :upload
      post :publish
      post :upload, :controller => :projects, :action=>:process_upload
      get :export
      get :export_with_files
      get :filter
      get :cv
      get :edit_cv
      resources :items do
        put :restore
        get :controlled_vocabulary_term
      end
      resources :schemas
    end
  end

  root :to => 'projects#index'

end
