class UpdatePlaybackStates
  def self.update
    new.update
  end

  def update
    threads = []
    updated_playback_states = []
    SpotifyUser.all.each do |spotify_user|
      threads << Thread.new do
        updated_playback_states << spotify_user.updated_playback_state
      end
    end
    threads.each(&:join)
    updated_playback_states.each do |updated_playback_state|
      SpotifyUser.find(
        updated_playback_state[:spotify_user_id]
      ).update(updated_playback_state[:playback_state])
    end
  end
end
