class TellClientsToRefreshTheirListenerList
  def self.tell
    new.tell
  end

  def tell
    ActionCable.server.broadcast('spotify_users_channel', {})
  end
end
