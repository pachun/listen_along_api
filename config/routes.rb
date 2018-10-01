Rails.application.routes.draw do
  resources :currently_playing_song, only: [:index]
  resources :listen_along, only: [:index]
end
