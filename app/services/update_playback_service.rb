class UpdatePlaybackService
  def self.update
    new.update
  end

  attr_reader :start_time, :num_listeners_whose_broadcaster_started_a_new_song

  def update
    update_playback_states

    unsync_listeners_whose_broadcaster_stopped_broadcasting
    unsync_listeners_who_started_a_new_song
    unsync_listeners_who_paused_their_music
    resync_listeners_who_hit_end_of_song
    resync_listeners_whose_broadcaster_started_a_new_song

    tell_clients_to_refresh_their_listener_list
  end

  private

  def update_playback_states
    SpotifyUser.all.each do |spotify_user|
      spotify_user.update(
        SpotifyService.new(spotify_user).current_playback_state
      )
    end
  end

  def unsync_listeners_whose_broadcaster_stopped_broadcasting
    listeners_whose_broadcaster_stopped_broadcasting.each do |listener|
      Rails.logger.info("#{listener.display_name} unsynced from #{listener.broadcaster.username} because #{listener.broadcaster.username} stopped broadcasting")
    end
    listeners_whose_broadcaster_stopped_broadcasting.update(broadcaster: nil)
  end

  def unsync_listeners_who_started_a_new_song
    listeners.each do |listener|
      if listener_started_new_song?(listener)
        Rails.logger.info("#{listener.display_name} unsynced from #{listener.broadcaster.username} because #{listener.display_name} started a new song")
        listener.update(broadcaster: nil)
      end
    end
  end

  def unsync_listeners_who_paused_their_music
    listeners_whose_music_is_paused.each do |listener|
      unless broadcaster_started_new_song?(listener)
        Rails.logger.info("#{listener.display_name} unsynced from #{listener.broadcaster.username} because #{listener.display_name} paused their music")
        listener.update(broadcaster: nil)
      end
    end
  end

  def resync_listeners_who_hit_end_of_song
    listeners_whose_music_is_paused.each do |listener|
      if broadcaster_started_new_song?(listener)
        SpotifyService.new(listener).listen_along(
          broadcaster: listener.broadcaster
        )
      end
    end
  end

  def resync_listeners_whose_broadcaster_started_a_new_song
    listeners.each do |listener|
      if broadcaster_started_new_song?(listener)
        SpotifyService.new(listener).listen_along(
          broadcaster: listener.broadcaster,
        )
      end
    end
  end

  def tell_clients_to_refresh_their_listener_list
    ActionCable.server.broadcast('spotify_users_channel', {})
  end

  def listener_started_new_song?(listener)
    !listener.broadcaster.changed_song? &&
      !listener.on_same_song_as_broadcaster?
  end

  def broadcaster_started_new_song?(listener)
    listener.broadcaster&.changed_song? &&
      !listener.on_same_song_as_broadcaster?
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
