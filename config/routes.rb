Sapphire::Application.routes.draw do

  resources :projects do 
    resources :collections
  end

  root :to => 'projects#index'

end
