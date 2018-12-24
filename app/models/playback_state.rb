class PlaybackState
  def self.from(api_response:, spotify_user:)
    new(api_response, spotify_user).playback_state
  end

  attr_reader :api_response, :spotify_user

  def initialize(api_response, spotify_user)
    @api_response = api_response
    @spotify_user = spotify_user
  end

  def playback_state
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
    @album_cover_url ||= JSON
      .parse(api_response.body)["item"]["album"]["images"][0]["url"]
  end

  def no_song_playing?
    @no_song_playing ||= \
      nothing_has_played_in_a_while? ||
      nothing_is_playing_now?
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
