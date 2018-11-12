module LoggerService
  def self.log_playback_resync(listener:, broadcaster:)
    Rails.logger.info(
      message: "playback resynced",
      context: {
        listener: listener.username,
        broadcaster: broadcaster.username,
      },
      event: {
        song: broadcaster.song_name,
      },
    )
  end

  def self.log_authentication(spotify_user)
    Rails.logger.info(
      message: "spotify user authenticated",
      event: "spotify user authenticated",
      context: {
        spotify_user: spotify_user,
      },
    )
  end

  def self.log_listen_along(listener:, broadcaster:)
    Rails.logger.info(
      message: "spotify user began listening along",
      context: {
        listener: listener.username,
        broadcaster: broadcaster.username,
      },
    )
  end

  def self.log_playback_update(
    duration:,
    unsynced_listeners_whose_broadcaster_stopped_broadcasting:,
    resynced_listeners_who_had_hit_end_of_song:,
    resynced_listeners_whose_broadcaster_started_a_new_song:
  )
    Rails.logger.info(
      message: "playback updated",
      event: {
        duration: "#{duration} seconds",
        unsynced_listeners_whose_broadcasters_stopped_broadcasting: unsynced_listeners_whose_broadcaster_stopped_broadcasting,
        resynced_listeners_who_had_hit_end_of_song: resynced_listeners_who_had_hit_end_of_song,
        resynced_listeners_whose_broadcaster_started_a_new_song: \
          resynced_listeners_whose_broadcaster_started_a_new_song,
      }
    )
  end
end
