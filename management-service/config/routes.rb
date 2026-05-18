Rails.application.routes.draw do
  post '/auth/login', to: 'auth#login'
  post '/auth/register', to: 'auth#register'
  resources :addresses
  resources :vehicles
  resources :drivers

  post 'login', to: 'sessions#create'
end
