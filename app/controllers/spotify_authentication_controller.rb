class SpotifyAuthenticationController < ApiController
  def index
    SpotifyCredential.create(
      access_token: spotify_credentials["access_token"],
      refresh_token: spotify_credentials["refresh_token"]
    )
    redirect_to listen_along_index_path
  end

  private

  def spotify_credentials
    @spotify_credentials ||= JSON.parse(spotify_token_request.body)
  end

  def spotify_token_request
    @spotify_token_request ||= Faraday
      .post("https://accounts.spotify.com/api/token") do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.headers["Authorization"] = "Basic #{client_id_and_secret}"
      req.body = {
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": "#{ENV["API_URL"]}/spotify_authentication",
      }
    end
  end

  def client_id_and_secret
    @client_id_and_secret ||= Base64.urlsafe_encode64(
      "#{ENV["SPOTIFY_CLIENT_ID"]}:#{ENV["SPOTIFY_CLIENT_SECRET"]}"
    )
  end

  def code
    params[:code]
  end
end
