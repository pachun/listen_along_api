class UpdatePlaybackService
  def self.update
    new.update
  end

  def update
    UpdatePlaybackStates.update(listening: true)
    UnsyncListenersWhoseBroadcasterStoppedBroadcasting.unsync
    UnsyncListenersWhoStartedANewSong.unsync
    ResyncListenersWhoseBroadcasterStartedANewSong.resync
    ResyncOutOfSyncListeners.resync
    UpdatePausedListenersPlayback.update
    CarryListenersToNewBroadcasters.carry
    TellClientsToRefreshTheirListenerList.tell
  end
end
