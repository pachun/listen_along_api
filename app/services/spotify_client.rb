class SpotifyClient
  SPOTIFY_AUTHORIZATION_URL = "https://accounts.spotify.com/api/token"
  SPOTIFY_API_URL = "https://api.spotify.com"
  CURRENTLY_PLAYING_SONG_ENDPOINT = "/v1/me/player/currently-playing"

  attr_reader :connection

  def initialize
    @connection = Faraday.new(SPOTIFY_API_URL) do |faraday|
      faraday.adapter(Faraday.default_adapter)
    end
  end

  def currently_playing_song_name
    response = song_request

    if spotify_access_token_expired?(response)
      refresh_access_token
      response = song_request
    end

    song_name(response)
  end

  private

  def song_name(song_request_response)
    if no_song_playing?(song_request_response)
      "No Song Playing"
    else
      JSON.parse(song_request_response.body)["item"]["name"]
    end
  end

  def no_song_playing?(song_request_response)
    no_content = 204
    song_request_response.status == no_content
  end

  def song_request
    connection.get(CURRENTLY_PLAYING_SONG_ENDPOINT) do |request|
      request.headers["Authorization"] = bearer_auth_header
    end
  end

  def bearer_auth_header
    "Bearer #{SpotifyCredential.last.access_token}"
  end

  def spotify_access_token_expired?(song_request_response)
    song_request_response.status == 401
  end

  def refresh_access_token
    token = JSON.parse(request_refreshed_access_token.body)["access_token"]
    SpotifyCredential.last.update(access_token: token)
  end

  def request_refreshed_access_token
    Faraday.post(SPOTIFY_AUTHORIZATION_URL) do |req|
      req.headers["Authorization"] = basic_auth_header
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = refresh_access_token_request_body
    end
  end

  def basic_auth_header
    client_id_and_secret = Base64.urlsafe_encode64(
      "#{ENV["SPOTIFY_CLIENT_ID"]}:#{ENV["SPOTIFY_CLIENT_SECRET"]}"
    )
    "Basic #{client_id_and_secret}"
  end

  def refresh_access_token_request_body
    Addressable::URI.new.tap do |addressable|
      addressable.query_values = {
        "grant_type" => "refresh_token",
        "refresh_token" => SpotifyCredential.last.refresh_token,
      }
    end.query
  end
end
