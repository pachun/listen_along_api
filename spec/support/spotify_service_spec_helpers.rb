module SpotifyServiceSpecHelpers
  def stub_get_playback_request(spotify_user, overwrites = {})
    stub_request(
      :get,
      "https://api.spotify.com/v1/me/player/currently-playing"
    ).with(
      headers: { "Authorization": "Bearer #{spotify_user.access_token}" },
    ).to_return(get_playback_response(spotify_user, overwrites))
  end

  def stub_set_playback_request(listener:, broadcaster:, overwrites: {})
    stub_request(
      :put,
      "https://api.spotify.com/v1/me/player/play"
    ).with(
      body: {
        "uris": [overwrites[:song_uri] || broadcaster.song_uri],
        "position_ms": broadcaster.millisecond_progress_into_song,
      }.to_json,
      headers: {
        "Authorization": "Bearer #{listener.access_token}",
      },
    ).to_return(
      status: 200,
    )
  end

  def stub_play_request(args = {})
    status = args[:expired_access_token] ? 401 : 200
    stub_request(
      :put,
      "https://api.spotify.com/v1/me/player/play"
    ).with(
      body: {
        "uris": [args[:song_uri]],
        "position_ms": args[:millisecond_progress],
      }.to_json,
      headers: {
        "Authorization": "Bearer #{args[:access_token]}",
      },
    ).to_return(
      status: status,
    )
  end

  def stub_currently_playing_request(args = {})
    access_token = args[:access_token]

    stub_request(
      :get,
      "https://api.spotify.com/v1/me/player/currently-playing"
    ).with(
      headers: { "Authorization": "Bearer #{access_token}" },
    ).to_return(currently_playing_response(args))
  end

  def stub_refresh_access_token_request(args = {})
    stub_request(
      :post,
      "https://accounts.spotify.com/api/token"
    ).with(
      body: {
        "grant_type": "refresh_token",
        "refresh_token": args[:refresh_token],
      },
      headers: {
        "Authorization": "Basic #{unauthenticated_request_header}",
        "Content-Type": "application/x-www-form-urlencoded",
      }
    ).to_return(
      status: 200,
      body: { "access_token": args[:refreshed_access_token] }.to_json,
    )
  end

  def stub_get_access_token_request(args = {})
    stub_request(
      :post,
      "https://accounts.spotify.com/api/token"
    ).with(
      headers: {
        "Authorization": "Basic #{unauthenticated_request_header}",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "grant_type": "authorization_code",
        "code": args[:authorization_code],
        "redirect_uri": "#{ENV["API_URL"]}/spotify_authentication",
      }
    ).to_return(
      status: 200,
      body: {
        access_token: args[:access_token],
        refresh_token: args[:refresh_token],
      }.to_json
    )
  end

  def stub_spotify_username_request(args = {})
    stub_request(
      :get,
      "https://api.spotify.com/v1/me",
    ).with( headers: { "Authorization": "Bearer #{args[:access_token]}" }).to_return(
      status: 200,
      body: { "id": args[:spotify_username] }.to_json,
    )
  end
end

def unauthenticated_request_header
  Base64.urlsafe_encode64(
    "#{ENV["SPOTIFY_CLIENT_ID"]}:#{ENV["SPOTIFY_CLIENT_SECRET"]}"
  )
end

def currently_playing_response(args)
  if args[:expired_access_token]
    { status: 401 }
  elsif args[:nothing_playing_response]
    { status: 204 }
  else
    {
      status: 200,
      body: {
        is_playing: args[:is_playing],
        progress_ms: args[:millisecond_progress],
        item: {
          name: args[:song_name],
          uri: args[:song_uri],
        }
      }.to_json,
    }
  end
end

def get_playback_response(spotify_user, overwrites)
  {
    status: 200,
    body: {
      is_playing: spotify_user.is_listening,
      progress_ms: spotify_user.millisecond_progress_into_song,
      item: {
        name: spotify_user.song_name,
        uri: overwrites[:song_uri] || spotify_user.song_uri,
      }
    }.to_json,
  }
end
