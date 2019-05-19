class SpotifyAuthenticationController < ApiController
  attr_reader :spotify_user

  def index
    authenticate
    listen_along
    redirect_to client
    registering_spotify_user.destroy
  end

  private

  def authenticate
    @spotify_user = SpotifyService.authenticate(
      registering_spotify_user: registering_spotify_user,
      using_authorization_code: code,
    )
  end

  def listen_along
    spotify_user.listen_to!(broadcaster) if broadcaster.present?
  end

  def broadcaster
    SpotifyUser.find_by(
      username: registering_spotify_user.broadcaster_username
    )
  end

  def registering_spotify_user
    RegisteringSpotifyUser.find_by(identifier: identifier)
  end

  def client
    registering_spotify_user.mobile ? mobile_app : web_app
  end

  def web_app
    "#{ENV["WEB_CLIENT_URL"]}?token=#{spotify_user.listen_along_token}"
  end

  def mobile_app
    "#{ENV["MOBILE_CLIENT_URL"]}?token=#{spotify_user.listen_along_token}&broadcaster_username=#{broadcaster.username}"
  end

  def code
    params[:code]
  end

  def identifier
    params[:state]
  end
end
