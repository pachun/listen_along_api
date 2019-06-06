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
    record_start_time
    get_updated_playback_states
    update_playback_states
    log_total_time
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

  def record_start_time
    @beginning_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def log_total_time
    ending_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    total_time = ending_time - @beginning_time
    Rails.logger.debug("playback_update_time -> #{total_time} seconds")
  end
end
