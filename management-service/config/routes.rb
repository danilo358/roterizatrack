Rails.application.routes.draw do
  resources :addresses
  resources :vehicles
  resources :drivers

  post 'login', to: 'sessions#create'
end
