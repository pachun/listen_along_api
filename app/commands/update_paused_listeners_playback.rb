class UpdatePausedListenersPlayback
  def self.update
    new.update
  end

  def update
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

  private

  def listeners_whose_music_is_paused
    @listeners_whose_music_is_paused ||= SpotifyUser
      .where(is_listening: false)
      .where.not(broadcaster: nil)
  end
end
