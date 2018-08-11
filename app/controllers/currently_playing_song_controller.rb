class CurrentlyPlayingSongController < ApplicationController
  def index
    render json: SpotifyClient.new.currently_playing_song_name
  end
end
