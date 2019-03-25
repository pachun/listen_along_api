class SpotifyService
  OAUTH_URL = "https://accounts.spotify.com/authorize"
  SPOTIFY_API_URL = "https://api.spotify.com"
  CURRENTLY_PLAYING_SONG_ENDPOINT = "/v1/me/player/currently-playing"
  PLAY_SONG_ENDPOINT = "/v1/me/player/play"
  SPOTIFY_USERNAME_ENDPOINT = "/v1/me"
  SPOTIFY_AUTHORIZATION_URL = "https://accounts.spotify.com/api/token"
  REPEAT_ON_ENDPOINT = "/v1/me/player/repeat?state=track"
  ADD_TO_LIBRARY_ENDPOINT = "/v1/me/tracks"
  AUTHORIZATION_SCOPES = [
    "user-read-recently-played",
    "user-top-read",

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

  def current_playback_state
    PlaybackState.from(
      api_response: song_request,
      spotify_user: spotify_user,
    )
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

  private

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
    spotify_response = Faraday.put(url) do |request|
      request.headers["Authorization"] = authenticated_header
    end
    Rails.logger.info({
      event: {
        type: "turn_on_repeat",
        spotify_username: spotify_user.username,
        request: {
          url: url,
          method: "PUT",
          headers: {
            "Authorization" => authenticated_header,
          },
        },
        response: {
          status: spotify_response.status,
          headers: spotify_response.headers,
          body: spotify_response.body,
        },
      },
    }.to_json)
  end

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
    url = SpotifyService::SPOTIFY_API_URL + PLAY_SONG_ENDPOINT
    spotify_response = Faraday.put(url) do |request|
      request.headers["Authorization"] = authenticated_header
      request.body = {
        "uris": [playback_state[:song_uri]],
        "position_ms": playback_state[:millisecond_progress_into_song],
      }.to_json
    end
    Rails.logger.info({
      event: {
        type: "set_playback",
        spotify_username: spotify_user.username,
        request: {
          url: url,
          method: "PUT",
          headers: {
            "Authorization" => authenticated_header,
          },
          body: {
            "uris": [playback_state[:song_uri]],
            "position_ms": playback_state[:millisecond_progress_into_song],
          }.to_json,
        },
        response: {
          status: spotify_response.status,
          headers: spotify_response.headers,
          body: spotify_response.body,
        },
      },
    }.to_json)
    spotify_response
  end

  def currently_playing_song_request
    url = SpotifyService::SPOTIFY_API_URL + CURRENTLY_PLAYING_SONG_ENDPOINT
    spotify_response = Faraday.get(url) do |request|
      request.headers["Authorization"] = authenticated_header
    end
    Rails.logger.info({
      event: {
        type: "get_playback",
        spotify_username: spotify_user.username,
        request: {
          url: url,
          method: "GET",
          headers: {
            "Authorization" => authenticated_header,
          },
        },
        response: {
          status: spotify_response.status,
          headers: spotify_response.headers,
          body: spotify_response.body.force_encoding("UTF-8"),
        },
      },
    }.to_json)
    spotify_response
  end

  def authenticating_header
    client_id = spotify_user.spotify_app.client_identifier
    client_secret = spotify_user.spotify_app.client_secret
    "Basic #{Base64.urlsafe_encode64("#{client_id}:#{client_secret}")}"
  end

  def refreshed_access_token_request
    url = SpotifyService::SPOTIFY_AUTHORIZATION_URL
    spotify_response = Faraday.post(url) do |req|
      req.headers["Authorization"] = authenticating_header
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = refresh_access_token_request_body
    end
    Rails.logger.info({
      event: {
        type: "refresh_access_token",
        spotify_username: spotify_user.username,
        request: {
          url: url,
          method: "POST",
          headers: {
            "Authorization" => authenticating_header,
            "Content-Type" => "application/x-www-form-urlencoded",
          },
          body: refresh_access_token_request_body,
        },
        response: {
          status: spotify_response.status,
          headers: spotify_response.headers,
          body: spotify_response.body,
        },
      },
    }.to_json)
    spotify_response
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
    bad_request = 400
    unauthorized = 401
    [bad_request, unauthorized].include?(spotify_response.status)
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
        update_spotify_tokens
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
      )
    end

    def update_spotify_tokens
      spotify_user.update(
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

    def avatar_url
      return @avatar_url if @avatar_url.present?

      if username_request["images"].length == 0
        @avatar_url = SpotifyUser::DEFAULT_AVATAR_URL
      else
        @avatar_url = username_request["images"]&.first&.dig("url")
      end
    end

    def username_request
      return @username_request if @username_request.present?

      url = SPOTIFY_API_URL + SPOTIFY_USERNAME_ENDPOINT
      spotify_response = Faraday.get(url) do |req|
        req.headers["Authorization"] = "Bearer #{access_token}"
      end
      Rails.logger.info({
        event: {
          type: "username_request",
          request: {
            url: url,
            method: "GET",
            headers: {
              "Authorization" => "Bearer #{access_token}",
            },
          },
          response: {
            status: spotify_response.status,
            headers: spotify_response.headers,
            body: spotify_response.body,
          },
        },
      }.to_json)
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
      Rails.logger.info({
        event: {
          type: "get_access_token",
          request: {
            url: url,
            method: "POST",
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded",
              "Authorization" => authenticating_header,
            },
            body: {
              "grant_type": "authorization_code",
              "code": authorization_code,
              "redirect_uri": "#{ENV["API_URL"]}/spotify_authentication",
            },
          },
          response: {
            status: spotify_response.status,
            headers: spotify_response.headers,
            body: spotify_response.body,
          },
        },
      }.to_json)

      @spotify_token_request = spotify_response
    end
  end
end
