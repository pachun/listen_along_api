class SpotifyAuthenticationController < ApiController
  attr_reader :spotify_user

  def index
    authenticate
    listen_along
    registering_spotify_user.destroy
    redirect_to listen_with_web_app
  end

  private

  def authenticate
    @spotify_user = SpotifyService.authenticate(
      registering_spotify_user: registering_spotify_user,
      using_authorization_code: code,
    )
  end

  def listen_along
    if broadcaster.present?
      SpotifyService.new(spotify_user).listen_along(
        broadcaster: broadcaster,
      )
    end
  end

  def broadcaster
    SpotifyUser.find_by(
      username: registering_spotify_user.broadcaster_username
    )
  end

  def registering_spotify_user
    RegisteringSpotifyUser.find_by(identifier: identifier)
  end

  def listen_with_web_app
    "#{ENV["CLIENT_URL"]}?token=#{spotify_user.listen_along_token}"
  end

  def code
    params[:code]
  end

  def identifier
    params[:state]
  end
end
