class UpdatePlaybackStates
  def self.update
    new.update
  end

  attr_accessor :threads, :updated_playback_states

  def initialize
    @threads = []
    @updated_playback_states = []
  end

  def update
    request_updated_playback_states_in_parallel
    wait_for_requests_to_finish
    update_playback_states
  end

  private

  def request_updated_playback_states_in_parallel
    SpotifyUser.all.each do |spotify_user|
      request_updated_playback_state_for(spotify_user)
    end
  end

  def request_updated_playback_state_for(spotify_user)
    threads << Thread.new do
      updated_playback_states << spotify_user.updated_playback_state
    end
  end

  def wait_for_requests_to_finish
    threads.each(&:join)
  end

  def update_playback_states
    updated_playback_states.each do |updated_playback_state|
      SpotifyUser.find(
        updated_playback_state[:spotify_user_id]
      ).update(updated_playback_state[:playback_state])
    end
  end
end
