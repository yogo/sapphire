Sapphire::Application.routes.draw do

  resources :projects do 
    resources :collections do
      resources :schemas
    end
  end

  root :to => 'projects#index'

end
