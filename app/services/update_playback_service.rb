class UpdatePlaybackService
  def self.update
    new.update
  end

  attr_reader :start_time, :num_listeners_whose_broadcaster_started_a_new_song

  def update
    update_playback_states

    unsync_listeners_whose_broadcaster_stopped_broadcasting
    unsync_listeners_who_started_a_new_song
    resync_listeners_whose_broadcaster_started_a_new_song
    update_paused_listeners_playback
    carry_listeners_to_new_broadcasters

    tell_clients_to_refresh_their_listener_list
  end

  private

  def carry_listeners_to_new_broadcasters
    broadcasters_who_started_listening_to_someone.each do |old_broadcaster|
      move_listeners_to_new_broadcaster(old_broadcaster)
    end
  end

  def broadcasters_who_started_listening_to_someone
    SpotifyUser.joins(:listeners).where.not(broadcaster: nil)
  end

  def move_listeners_to_new_broadcaster(old_broadcaster)
    old_broadcaster.listeners.update_all(
      spotify_user_id: old_broadcaster.broadcaster.id
    )
  end

  def update_playback_states
    SpotifyUser.all.each do |spotify_user|
      spotify_user.update_playback_state
    end
  end

  def unsync_listeners_whose_broadcaster_stopped_broadcasting
    listeners_whose_broadcaster_stopped_broadcasting.update(broadcaster: nil)
  end

  def unsync_listeners_who_started_a_new_song
    listeners.each do |listener|
      if listener.started_playing_music_independently?
        listener.stop_listening_along!
      end
    end
  end

  def update_paused_listeners_playback
    listeners_whose_music_is_paused.each do |listener|
      if listener.broadcaster_started_new_song?
        listener.resync_with_broadcaster!
      elsif listener.may_have_intentionally_paused?
        listener.update(maybe_intentionally_paused: true)
      elsif listener.intentionally_paused?
        listener.stop_listening_along!
      end
    end
  end

  def resync_listeners_whose_broadcaster_started_a_new_song
    listeners.each do |listener|
      if listener.broadcaster_started_new_song?
        listener.resync_with_broadcaster!
      end
    end
  end

  def tell_clients_to_refresh_their_listener_list
    ActionCable.server.broadcast('spotify_users_channel', {})
  end

  def listeners
    SpotifyUser
      .where(is_listening: true)
      .where.not(broadcaster: nil)
  end

  def listeners_whose_music_is_paused
    @listeners_whose_music_is_paused ||= SpotifyUser
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
