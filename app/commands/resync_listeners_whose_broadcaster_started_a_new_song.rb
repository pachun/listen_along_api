class ResyncListenersWhoseBroadcasterStartedANewSong
  def self.resync
    new.resync
  end

  def resync
    listeners.each do |listener|
      if listener.broadcaster_started_new_song?
        listener.resync_with_broadcaster!
      end
    end
  end

  private

  def listeners
    SpotifyUser
      .where(is_listening: true)
      .where.not(broadcaster: nil)
  end
end
