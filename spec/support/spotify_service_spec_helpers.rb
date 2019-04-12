module SpotifyServiceSpecHelpers
  def stub_spotify_service_listen_alongs
    spotify_service_double = instance_double(SpotifyService)
    allow(SpotifyService).to receive(:new)
      .and_return(spotify_service_double)
    allow(spotify_service_double).to receive(:listen_along)
    allow(spotify_service_double).to receive(:turn_off_repeat)
  end

  def stub_turn_off_repeat_request(spotify_user)
    stub_request(:put, "https://api.spotify.com/v1/me/player/repeat?state=off")
      .with(headers: {
        "Authorization" => "Bearer #{spotify_user.access_token}"
      }).to_return(status: 200, body: "", headers: {})
  end

  def stub_start_playback_loop_request(args = {})
    access_token = args[:access_token] ? args[:access_token] : args[:spotify_user].access_token
    stub_request(
      :put,
      "https://api.spotify.com/v1/me/player/repeat?state=track",
    ).with(
      headers: { "Authorization": "Bearer #{access_token}" },
    )
  end

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
        "Authorization": "Basic #{unauthenticated_request_header(args[:spotify_app])}",
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
        "Authorization": "Basic #{unauthenticated_request_header(args[:registering_spotify_user].spotify_app)}",
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

  def stub_add_song_to_library_request(access_token:, song_id:)
    stub_request(
      :put,
      "https://api.spotify.com/v1/me/tracks?ids=#{song_id}")
      .with(
          headers: {
        "Authorization"=>"Bearer #{access_token}",
      }).to_return(status: 200, body: "", headers: {})
  end

  def stub_spotify_username_request(args = {})
    if args[:avatar_url]
      @images = [ "url": args[:avatar_url] ]
    else
      @images = []
    end

    stub_request(
      :get,
      "https://api.spotify.com/v1/me",
    ).with( headers: { "Authorization": "Bearer #{args[:access_token]}" }).to_return(
      status: 200,
      body: {
        "id": args[:spotify_username],
        "display_name": args[:full_name],
        "images": @images,
      }.to_json,
    )
  end
end

def unauthenticated_request_header(spotify_app)
  client_id = spotify_app.client_identifier
  client_secret = spotify_app.client_secret
  Base64.urlsafe_encode64(
    "#{client_id}:#{client_secret}"
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
          album: {
            images: [{
              url: args[:album_url],
            }],
          },
          artists: [{ "name": nil }]
        }
      }.to_json,
    }
  end
end

def get_playback_response(spotify_user, overwrites)
  artists = overwrites[:song_artists]&.map { |artist| { name: artist } }
  artists ||= [{name: nil}]
  {
    status: 200,
    body: {
      is_playing: overwrites[:is_listening] || spotify_user.is_listening,
      progress_ms: overwrites[:millisecond_progress_into_song] || spotify_user.millisecond_progress_into_song,
      item: {
        name: overwrites[:song_name] || spotify_user.song_name,
        uri: overwrites[:song_uri] || spotify_user.song_uri,
        album: {
          images: [{
            url: overwrites[:album_url],
          }],
        },
        artists: artists,
      }
    }.to_json,
  }
end
