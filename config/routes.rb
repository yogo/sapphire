Sapphire::Application.routes.draw do

  resources :projects do 
    get :upload
    post :upload, :action=>:process_upload
    resources :collections do
      resources :items
      resources :schemas
    end
  end

  root :to => 'projects#index'

end
