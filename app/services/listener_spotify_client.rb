class ListenerSpotifyClient
  SPOTIFY_AUTHORIZATION_URL = "https://accounts.spotify.com/api/token"
  SPOTIFY_API_URL = "https://api.spotify.com"
  LISTEN_ALONG_ENDPOINT = "v1/me/player/play"

  def listen_along
    @song = BroadcasterSpotifyClient.new.currently_playing_song
    @connection = Faraday.new(SPOTIFY_API_URL) do |faraday|
      faraday.adapter(Faraday.default_adapter)
    end

    response = listen_along_request
    if spotify_access_token_expired?(response)
      refresh_access_token
      response = listen_along_request
    end
  end

  private

  def listen_along_request
    @connection.put(LISTEN_ALONG_ENDPOINT) do |request|
      request.headers["Authorization"] = "Bearer #{SpotifyCredential.last.access_token}"
      request.body = {
        "uris": ["#{@song[:uri]}"],
        "position_ms": @song[:millisecond_progress]
      }.to_json
    end
  end

  def spotify_access_token_expired?(request)
    request.status == 401
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
