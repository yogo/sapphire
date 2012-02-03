Sapphire::Application.routes.draw do

  resources :projects do 
    resources :collections do
      resource :items
    end
  end

  root :to => 'projects#index'

end
