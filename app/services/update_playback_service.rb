class UpdatePlaybackService
  def self.update
    new.update
  end

  attr_reader :start_time, :num_listeners_whose_broadcaster_started_a_new_song

  def update
    update_playback_states

    unsync_listeners_whose_broadcaster_stopped_broadcasting
    resync_listeners_who_hit_end_of_song
    resync_listeners_whose_broadcaster_started_a_new_song
  end

  private

  def update_playback_states
    SpotifyUser.all.each do |spotify_user|
      spotify_user.update(
        SpotifyService.new(spotify_user).current_playback_state
      )
    end
  end

  def resync_listeners_whose_broadcaster_started_a_new_song
    listeners = SpotifyUser
      .where(is_listening: true)
      .where.not(broadcaster: nil)

    listeners.each do |listener|
      if listener.song_uri != listener.broadcaster.song_uri
        SpotifyService.new(listener).listen_along(
          broadcaster: listener.broadcaster,
        )
      end
    end
  end

  def unsync_listeners_whose_broadcaster_stopped_broadcasting
    listeners_whose_broadcaster_stopped_broadcasting.update(broadcaster: nil)
  end

  def resync_listeners_who_hit_end_of_song
    listeners_who_hit_end_of_song.each do |listener|
      SpotifyService.new(listener).listen_along(
        broadcaster: listener.broadcaster
      )
    end
  end

  def listeners_who_hit_end_of_song
    @listeners_who_hit_end_of_song ||= SpotifyUser
      .where(is_listening: false)
      .where.not(broadcaster: nil)
  end

  def listeners_whose_broadcaster_stopped_broadcasting
    @listeners_whose_broadcaster_stopped_broadcasting ||= \
      SpotifyUser.where(broadcaster: not_listening)
  end

  def not_listening
    @not_listening ||= SpotifyUser.where(is_listening: false)
  end
end
