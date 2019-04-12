class UpdatePlaybackService
  def self.update
    new.update
  end

  def update
    t1 = Time.now
    UpdatePlaybackStates.update
    t2 = Time.now
    UnsyncListenersWhoseBroadcasterStoppedBroadcasting.unsync
    t3 = Time.now
    UnsyncListenersWhoStartedANewSong.unsync
    t4 = Time.now
    ResyncListenersWhoseBroadcasterStartedANewSong.resync
    t5 = Time.now
    UpdatePausedListenersPlayback.update
    t6 = Time.now
    CarryListenersToNewBroadcasters.carry
    t7 = Time.now
    TellClientsToRefreshTheirListenerList.tell
    t8 = Time.now
    total_time = t8 - t1
    update_playback_state_time = t2 - t1
    unsync_listeners_whose_broadcaster_stopped_broadcasting_time = t3 - t2
    unsync_listeners_who_started_a_new_song_time = t4 - t3
    resync_listeners_whose_broadcasters_started_a_new_song_time = t5 - t4
    update_paused_listeners_playback_time = t6 - t5
    carry_listeners_to_new_broadcasters_time = t7 - t6
    tell_clients_to_refresh_their_listener_list_time = t8 - t7
    Rails.logger.info({
      event: {
        type: "update_playback_service_durations",
        total_time: total_time,
        update_playback_state_time: update_playback_state_time,
        unsync_listeners_whose_broadcaster_stopped_broadcasting_time: unsync_listeners_whose_broadcaster_stopped_broadcasting_time,
        unsync_listeners_who_started_a_new_song_time: unsync_listeners_who_started_a_new_song_time,
        resync_listeners_whose_broadcasters_started_a_new_song_time: resync_listeners_whose_broadcasters_started_a_new_song_time,
        update_paused_listeners_playback_time: update_paused_listeners_playback_time,
        carry_listeners_to_new_broadcasters_time: carry_listeners_to_new_broadcasters_time,
        tell_clients_to_refresh_their_listener_list_time: tell_clients_to_refresh_their_listener_list_time,
      }
    }.to_json)
  end
end
