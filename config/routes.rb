Rails.application.routes.draw do
  resources :currently_playing_song, only: [:index]
end
