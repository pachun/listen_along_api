class UpdatePlaybackStates
  NUM_CONCURRENT_UPDATES = 5

  def self.update
    new.update
  end

  attr_accessor :updated_playback_states

  def initialize
    @updated_playback_states = []
  end

  def update
    get_updated_playback_states
    update_playback_states
  end

  private

  def get_updated_playback_states
    SpotifyApp.concurrently_updatable_spotify_user_batches(
      batch_size: NUM_CONCURRENT_UPDATES
    ).each do |updatable_spotify_user_batch|
      get_updated_batch_playback_states(updatable_spotify_user_batch)
    end
  end

  def get_updated_batch_playback_states(updatable_spotify_user_batch)
    threads = []
    updatable_spotify_user_batch.each do |spotify_user|
      threads << Thread.new do
        updated_playback_states << spotify_user.updated_playback_state
      end
    end
    threads.each(&:join)
  end

  def update_playback_states
    updated_playback_states.each do |updated_playback_state|
      SpotifyUser
        .find(updated_playback_state[:spotify_user_id])
        .update(updated_playback_state[:playback_state])
    end
  end
end
