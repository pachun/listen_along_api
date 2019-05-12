class ResyncOutOfSyncListeners
  def self.resync
    new.resync
  end

  def resync
    listeners_who_are_out_of_sync_with_their_broadcasters.each do |listener|
      listener.resync_with_broadcaster!
    end
  end

  def listeners_who_are_out_of_sync_with_their_broadcasters
    SpotifyUser
      .where("spotify_users.spotify_user_id IS NOT NULL")
      .joins(:broadcaster)
      .where(listeners_who_are_unsynced_sql)
  end

  private

  def listeners_who_are_unsynced_sql
    <<-SQL
      ABS(
        CAST(spotify_users.millisecond_progress_into_song AS int) -
        CAST(broadcasters_spotify_users.millisecond_progress_into_song as INT)
      ) >= 3000
    SQL
  end
end
