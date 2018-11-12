class PlaybackState
  def self.from_spotify(api_response)
    new(api_response).playback_state
  end

  attr_reader :api_response

  def initialize(api_response)
    @api_response = api_response
  end

  def playback_state
    {
      is_listening: is_listening?,
      song_name: song_name,
      song_uri: song_uri,
      millisecond_progress_into_song: millisecond_progress_into_song,
    }
  end

  private

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
