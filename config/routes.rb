Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  root to: "admin/spotify_users#index"

  resources :listeners, only: [:index]
  resources :listen_along, only: [:index]
  resources :spotify_authentication, only: [:index]
end
