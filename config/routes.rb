Rails.application.routes.draw do
  resources :registering_spotify_users, only: [:new]
  resources :spotify_authentication, only: [:index]

  resources :spotify_users, only: [:index, :update]

  # untested but required - do not remove:
  mount ActionCable.server => '/cable'

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  root to: "admin/spotify_users#index"
end
