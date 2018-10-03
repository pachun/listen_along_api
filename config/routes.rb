Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  resources :currently_playing_song, only: [:index]
  resources :listen_along, only: [:index]
  resources :spotify_authentication, only: [:index]
end
