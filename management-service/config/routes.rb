Rails.application.routes.draw do
  post '/auth/login', to: 'auth#login'
  resources :addresses
  resources :vehicles
  resources :drivers

  post 'login', to: 'sessions#create'
end
