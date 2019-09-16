class PlaybackState
  def self.from(api_response:, spotify_user:)
    new(api_response, spotify_user).playback_state
  end

  def self.not_listening_state
    {
      is_listening: false,
      song_name: nil,
      song_uri: nil,
      millisecond_progress_into_song: nil,
      broadcaster: nil,
    }
  end

  attr_reader :api_response, :spotify_user

  def initialize(api_response, spotify_user)
    @api_response = api_response
    @spotify_user = spotify_user
  end

  def playback_state
    return ::PlaybackState.not_listening_state if api_response.status == 400
    {
      is_listening: is_listening?,
      song_name: song_name,
      song_uri: song_uri,
      millisecond_progress_into_song: millisecond_progress_into_song,
      last_song_uri: spotify_user.song_uri,
      song_album_cover_url: song_album_cover_url,
      song_artists: song_artists,
    }
  end

  private

  def song_artists
    @song_artists ||= no_song_playing? ? nil : artists
  end

  def song_album_cover_url
    @song_album_cover_url ||= no_song_playing? ? nil : album_cover_url
  end

  def is_listening?
    @is_listening ||= !no_song_playing?
  end

  def song_name
    @song_name ||= no_song_playing? ? nil : name
  end

  def song_uri
    @song_uri ||= no_song_playing? ? nil : uri
  end

  def millisecond_progress_into_song
    @millisecond_progress_into_song ||= \
      no_song_playing? ? nil : millisecond_progress
  end

  def name
    @name ||= JSON.parse(api_response.body)["item"]["name"]
  end

  def uri
    @uri ||= JSON.parse(api_response.body)["item"]["uri"]
  end

  def millisecond_progress
    @millisecond_progress ||= JSON.parse(api_response.body)["progress_ms"]
  end

  def artists
    @artists ||= JSON.parse(api_response.body)["item"]["artists"]
      .map do |artist_json|

      artist_json["name"]
    end
  end

  def album_cover_url
    if has_album_cover?
      @album_cover_url ||= JSON
        .parse(api_response.body)["item"]["album"]["images"][0]["url"]
    else
      @album_cover_url ||= ""
    end
  end

  def has_album_cover?
    @has_album_cover ||= JSON
      .parse(api_response.body)["item"]["album"]["images"][0].present?
  end

  def no_song_playing?
    @no_song_playing ||= \
      nothing_has_played_in_a_while? ||
      nothing_is_playing_now? ||
      is_listening_to_spotify_podcast
  end

  def is_listening_to_spotify_podcast
    @is_listening_to_spotify_podcast ||= JSON
      .parse(api_response.body)["currently_playing_type"] == "episode"
  end

  def nothing_has_played_in_a_while?
    @nothing_has_played_in_a_while ||= \
      api_response.status == 204
  end

  def nothing_is_playing_now?
    @nothing_is_playing_now ||= \
      JSON.parse(api_response.body)["is_playing"] == false
  end
end
