require 'sidekiq/web'

Rails.application.routes.draw do
  resources :registering_spotify_users, only: [:new]
  resources :spotify_authentication, only: [:index]

  resources :spotify_users, only: [:index]
  resources :feedback, only: [:create]

  post "listen_along", to: "spotify_users#listen_along"
  put "add_to_library", to: "spotify_users#add_to_library"

  mount ActionCable.server => '/cable'

  mount Sidekiq::Web => '/sidekiq'
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  root to: "admin/spotify_users#index"
end
