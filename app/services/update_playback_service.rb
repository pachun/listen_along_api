class UpdatePlaybackService
  def self.update
    new.update
  end

  def update
    UpdatePlaybackStates.update
    UnsyncListenersWhoseBroadcasterStoppedBroadcasting.unsync
    UnsyncListenersWhoStartedANewSong.unsync
    ResyncListenersWhoseBroadcasterStartedANewSong.resync
    UpdatePausedListenersPlayback.update
    CarryListenersToNewBroadcasters.carry
    TellClientsToRefreshTheirListenerList.tell
  end
end
