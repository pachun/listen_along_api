class UnsyncListenersWhoStartedANewSong
  def self.unsync
    new.unsync
  end

  def unsync
    listeners.each do |listener|
      if listener.started_playing_music_independently?
        listener.stop_listening_along!
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
