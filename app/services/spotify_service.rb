class SpotifyService
  SPOTIFY_API_URL = "https://api.spotify.com"
  CURRENTLY_PLAYING_SONG_ENDPOINT = "/v1/me/player/currently-playing"
  PLAY_SONG_ENDPOINT = "/v1/me/player/play"
  SPOTIFY_USERNAME_ENDPOINT = "/v1/me"
  SPOTIFY_AUTHORIZATION_URL = "https://accounts.spotify.com/api/token"
  AUTHENTICATING_HEADER = "Basic #{Base64.urlsafe_encode64(
    "#{ENV["SPOTIFY_CLIENT_ID"]}:#{ENV["SPOTIFY_CLIENT_SECRET"]}"
  )}"

  def self.authenticate(using_authorization_code:)
    SpotifyAuthenticationService.authenticate(
      using_authorization_code: using_authorization_code
    )
  end

  attr_reader :spotify_user

  def initialize(spotify_user)
    @spotify_user = spotify_user
  end

  def current_playback_state
    PlaybackState.from_spotify(song_request)
  end

  def listen_along(broadcaster:)
    playback_state = SpotifyService.new(broadcaster).current_playback_state
    if spotify_access_token_expired?(listen_along_request(playback_state))
      refresh_access_token
      listen_along_request(playback_state)
    end
    spotify_user.update(
      broadcaster: broadcaster,
      song_name: broadcaster.song_name,
      song_uri: broadcaster.song_uri,
      millisecond_progress_into_song: \
        broadcaster.millisecond_progress_into_song,
    )
  end

  private

  def song_request
    request = currently_playing_song_request

    if spotify_access_token_expired?(request)
      refresh_access_token
      currently_playing_song_request
    else
      request
    end
  end

  def listen_along_request(playback_state)
    Faraday.put(SpotifyService::SPOTIFY_API_URL + PLAY_SONG_ENDPOINT) do |request|
      request.headers["Authorization"] = authenticated_header
      request.body = {
        "uris": [playback_state[:song_uri]],
        "position_ms": playback_state[:millisecond_progress_into_song],
      }.to_json
    end
  end

  def currently_playing_song_request
    Faraday.get(SpotifyService::SPOTIFY_API_URL + CURRENTLY_PLAYING_SONG_ENDPOINT) do |request|
      request.headers["Authorization"] = authenticated_header
    end
  end

  def refreshed_access_token_request
    Faraday.post(SpotifyService::SPOTIFY_AUTHORIZATION_URL) do |req|
      req.headers["Authorization"] = AUTHENTICATING_HEADER
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = refresh_access_token_request_body
    end
  end

  def refresh_access_token_request_body
    Addressable::URI.new.tap do |addressable|
      addressable.query_values = {
        "grant_type" => "refresh_token",
        "refresh_token" => spotify_user.refresh_token,
      }
    end.query
  end

  def refresh_access_token
    token = JSON.parse(refreshed_access_token_request.body)["access_token"]
    spotify_user.update(access_token: token)
  end

  def spotify_access_token_expired?(spotify_response)
    unauthorized = 401
    spotify_response.status == unauthorized
  end

  def authenticated_header
    "Bearer #{spotify_user.access_token}"
  end

  class SpotifyAuthenticationService
    def self.authenticate(using_authorization_code:)
      new(using_authorization_code).authenticate
    end

    attr_reader :authorization_code

    def initialize(authorization_code)
      @authorization_code = authorization_code
    end

    def authenticate
      SpotifyUser
        .find_or_create_by(username: listener_username)
        .tap do |spotify_user|

        spotify_user.update(
          access_token: access_token,
          refresh_token: refresh_token,
        )
      end
    end

    private

    def access_token
      @access_token ||= spotify_user_json["access_token"]
    end

    def refresh_token
      @refresh_token ||= spotify_user_json["refresh_token"]
    end

    def listener_username
      @listener_username ||= JSON.parse(
        Faraday.get(SPOTIFY_API_URL + SPOTIFY_USERNAME_ENDPOINT) do |req|
          req.headers["Authorization"] = "Bearer #{access_token}"
        end.body
      )["id"]
    end

    def spotify_user_json
      @spotify_user_json ||= JSON.parse(spotify_token_request.body)
    end

    def spotify_token_request
      @spotify_token_request ||= Faraday
        .post(SPOTIFY_AUTHORIZATION_URL) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.headers["Authorization"] = AUTHENTICATING_HEADER
        req.body = {
          "grant_type": "authorization_code",
          "code": authorization_code,
          "redirect_uri": "#{ENV["API_URL"]}/spotify_authentication",
        }
      end
    end
  end
end
