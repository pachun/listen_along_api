class SpotifyService
  OAUTH_URL = "https://accounts.spotify.com/authorize"
  SPOTIFY_API_URL = "https://api.spotify.com"
  CURRENTLY_PLAYING_SONG_ENDPOINT = "/v1/me/player/currently-playing"
  PLAY_SONG_ENDPOINT = "/v1/me/player/play"
  SPOTIFY_USERNAME_ENDPOINT = "/v1/me"
  SPOTIFY_AUTHORIZATION_URL = "https://accounts.spotify.com/api/token"
  REPEAT_ON_ENDPOINT = "/v1/me/player/repeat?state=track"
  REPEAT_OFF_ENDPOINT = "/v1/me/player/repeat?state=off"
  ADD_TO_LIBRARY_ENDPOINT = "/v1/me/tracks"
  AUTHORIZATION_SCOPES = [
    "user-read-recently-played",
    # "user-top-read", # https://github.com/spotify/web-api/issues/1262

    "user-library-modify",
    "user-library-read",

    "playlist-read-private",
    "playlist-modify-public",
    "playlist-modify-private",
    "playlist-read-collaborative",

    "user-read-email",
    "user-read-birthdate",
    "user-read-private",

    "user-read-playback-state",
    "user-modify-playback-state",
    "user-read-currently-playing",

    "app-remote-control",
    "streaming",

    "user-follow-read",
    "user-follow-modify",
  ]

  def self.oauth_url(registering_spotify_user:)
    redirect_uri = "#{URI.encode(ENV["API_URL"])}/spotify_authentication"

    params = [
      ["client_id", registering_spotify_user.spotify_app.client_identifier],
      ["response_type", "code"],
      ["redirect_uri", redirect_uri],
      ["scope", AUTHORIZATION_SCOPES.join("%20")],
      ["state", registering_spotify_user.identifier]
    ]

    params.each_with_index.inject(OAUTH_URL) do |previous, iterator|
      param, index = iterator
      previous + (index == 0 ? "?" : "&") + param.join("=")
    end
  end

  def self.authenticate(registering_spotify_user:, using_authorization_code:)
    SpotifyAuthenticationService.authenticate(
      registering_spotify_user: registering_spotify_user,
      using_authorization_code: using_authorization_code
    )
  end

  attr_reader :spotify_user

  def initialize(spotify_user)
    @spotify_user = spotify_user
  end

  def updatable_state
    {
      spotify_user_id: spotify_user.id,
      playback_state: current_playback_state,
    }
  end

  def current_playback_state
    request = song_request

    if hit_spotify_api_rate_limit?(request)
      log_spotify_api_rate_limit_hit(spotify_user)
      {}
    else
      PlaybackState.from(api_response: request, spotify_user: spotify_user)
    end
  end

  def listen_along(broadcaster:)
    refresh_token_and_listen_along(broadcaster: broadcaster)
    turn_on_repeat
    update_listener_state(broadcaster)
  end

  def add_to_library(song_id:)
    url = SpotifyService::SPOTIFY_API_URL +
      ADD_TO_LIBRARY_ENDPOINT +
      "?ids=#{song_id}"
    Faraday.put(url) do |request|
      request.headers["Authorization"] = authenticated_header
    end
  end

  def turn_off_repeat
    url = SpotifyService::SPOTIFY_API_URL + REPEAT_OFF_ENDPOINT
    Faraday.put(url) do |request|
      request.headers["Authorization"] = authenticated_header
    end
  end

  def updated_avatar_state
    url = SPOTIFY_API_URL + SPOTIFY_USERNAME_ENDPOINT
    spotify_response = Faraday.get(url) do |req|
      req.headers["Authorization"] = "Bearer #{spotify_user.access_token}"
    end

    {
      spotify_user_id: spotify_user.id,
      avatar_url: JSON.parse(spotify_response.body)["images"]&.first&.dig("url"),
    }
  end

  private

  def log_spotify_api_rate_limit_hit(spotify_user)
    SpotifyApiRateLimitHit.create(
      spotify_user: spotify_user,
      spotify_app: spotify_user.spotify_app,
    )
  end

  def hit_spotify_api_rate_limit?(request)
    request.status == 429
  end

  def refresh_token_and_listen_along(broadcaster:)
    playback_state = SpotifyService.new(broadcaster).current_playback_state
    if spotify_access_token_expired?(listen_along_request(playback_state))
      refresh_access_token
      listen_along_request(playback_state)
    end
  end

  def update_listener_state(broadcaster)
    spotify_user.update(
      broadcaster: broadcaster,
      song_name: broadcaster.song_name,
      song_uri: broadcaster.song_uri,
      millisecond_progress_into_song: \
        broadcaster.millisecond_progress_into_song,
    )
  end

  def turn_on_repeat
    url = SpotifyService::SPOTIFY_API_URL + REPEAT_ON_ENDPOINT
    Faraday.put(url) do |request|
      request.headers["Authorization"] = authenticated_header
    end
  end

  def song_request
    request = currently_playing_song_request

    if spotify_access_token_expired?(request)
      refresh_access_token
      request = currently_playing_song_request
    end

    request
  end

  def listen_along_request(playback_state)
    url = SpotifyService::SPOTIFY_API_URL + PLAY_SONG_ENDPOINT
    Faraday.put(url) do |request|
      request.headers["Authorization"] = authenticated_header
      request.body = {
        "uris": [playback_state[:song_uri]],
        "position_ms": playback_state[:millisecond_progress_into_song],
      }.to_json
    end
  end

  def currently_playing_song_request
    url = SpotifyService::SPOTIFY_API_URL + CURRENTLY_PLAYING_SONG_ENDPOINT
    Faraday.get(url) do |request|
      request.headers["Authorization"] = authenticated_header
    end
  end

  def authenticating_header
    client_id = spotify_user.spotify_app.client_identifier
    client_secret = spotify_user.spotify_app.client_secret
    "Basic #{Base64.urlsafe_encode64("#{client_id}:#{client_secret}")}"
  end

  def refreshed_access_token_request
    url = SpotifyService::SPOTIFY_AUTHORIZATION_URL
    Faraday.post(url) do |req|
      req.headers["Authorization"] = authenticating_header
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
    def self.authenticate(registering_spotify_user:, using_authorization_code:)
      new(registering_spotify_user, using_authorization_code).authenticate
    end

    attr_reader :authorization_code, :registering_spotify_user

    def initialize(registering_spotify_user, authorization_code)
      @registering_spotify_user = registering_spotify_user
      @authorization_code = authorization_code
    end

    def spotify_user
      SpotifyUser.find_by(username: spotify_username)
    end

    def authenticate
      if spotify_user.present?
        update_existing_spotify_user
      else
        create_new_spotify_user
      end

      spotify_user
    end

    private

    def create_new_spotify_user
      SpotifyUser.create(
        spotify_app: registering_spotify_user.spotify_app,
        username: spotify_username,
        display_name: display_name,
        access_token: access_token,
        refresh_token: refresh_token,
        listen_along_token: new_token,
        avatar_url: avatar_url,
        email: email,
      )
    end

    def update_existing_spotify_user
      spotify_user.update(
        spotify_app: registering_spotify_user.spotify_app,
        access_token: access_token,
        refresh_token: refresh_token,
      )
    end

    def new_token
      (0...32).map { ('a'..'z').to_a[rand(26)] }.join
    end

    def access_token
      @access_token ||= spotify_user_json["access_token"]
    end

    def refresh_token
      @refresh_token ||= spotify_user_json["refresh_token"]
    end

    def spotify_username
      @spotify_username ||= username_request["id"]
    end

    def display_name
      @display_name ||= username_request["display_name"]
    end

    def email
      @email ||= username_request["email"]
    end

    def avatar_url
      return @avatar_url if @avatar_url.present?

      if no_spotify_profile_image_set? && email.present?
        @avatar_url = gravatar_from(email)
      elsif no_spotify_profile_image_set? && !email.present?
        @avatar_url = gravatar_from(spotify_username)
      else
        @avatar_url = username_request["images"]&.first&.dig("url")
      end
    end

    def no_spotify_profile_image_set?
      username_request["images"].length == 0
    end

    def gravatar_from(key)
      hash = Digest::MD5.hexdigest(key.strip.downcase)
      "https://www.gravatar.com/avatar/#{hash}?d=robohash&size=400"
    end

    def username_request
      return @username_request if @username_request.present?

      url = SPOTIFY_API_URL + SPOTIFY_USERNAME_ENDPOINT
      spotify_response = Faraday.get(url) do |req|
        req.headers["Authorization"] = "Bearer #{access_token}"
      end
      @username_request = JSON.parse(spotify_response.body)
    end

    def spotify_user_json
      @spotify_user_json ||= JSON.parse(spotify_token_request.body)
    end

    def authenticating_header
      client_id = registering_spotify_user.spotify_app.client_identifier
      client_secret = registering_spotify_user.spotify_app.client_secret
      "Basic #{Base64.urlsafe_encode64("#{client_id}:#{client_secret}")}"
    end

    def spotify_token_request
      return @spotify_token_request if @spotify_token_request

      url = SPOTIFY_AUTHORIZATION_URL
      spotify_response = Faraday
        .post(url) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.headers["Authorization"] = authenticating_header
        req.body = {
          "grant_type": "authorization_code",
          "code": authorization_code,
          "redirect_uri": "#{ENV["API_URL"]}/spotify_authentication",
        }
      end

      @spotify_token_request = spotify_response
    end
  end
end
