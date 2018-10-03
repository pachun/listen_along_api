class CurrentlyPlayingSongController < ApiController
  def index
    render json: BroadcasterSpotifyClient.new.currently_playing_song[:name]
  end
end
