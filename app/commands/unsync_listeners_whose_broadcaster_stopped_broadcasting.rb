class UnsyncListenersWhoseBroadcasterStoppedBroadcasting
  def self.unsync
    new.unsync
  end

  def unsync
    listeners_whose_broadcaster_stopped_broadcasting.each do |listener|
      listener.stop_listening_along!
    end
  end

  private

  def listeners_whose_broadcaster_stopped_broadcasting
    @listeners_whose_broadcaster_stopped_broadcasting ||= \
      SpotifyUser.where(broadcaster: not_listening)
  end

  def not_listening
    @not_listening ||= SpotifyUser.where(is_listening: false)
  end
end
