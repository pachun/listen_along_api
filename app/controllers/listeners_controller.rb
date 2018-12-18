class ListenersController < ApiController
  def index
    render json: broadcasters
  end

  private

  def broadcasters
    SpotifyUser.where(is_listening: true).map do |spotify_user|
      {
        username: spotify_user.username,
        broadcaster: spotify_user&.broadcaster&.username,
      }
    end
  end
end
