class RefreshExpiredAvatars
  FORBIDDEN = 403

  def self.refresh
    new.refresh
  end

  attr_accessor :threads, :updated_avatar_states

  def initialize
    @threads = []
    @updated_avatar_states = []
  end

  def refresh
    request_updated_expired_avatars_in_parallel
    wait_for_requests_to_finish
    update_expired_avatars
  end

  private

  def request_updated_expired_avatars_in_parallel
    SpotifyUser.all.each do |spotify_user|
      request_updated_avatar_for(spotify_user)
    end
  end

  def request_updated_avatar_for(spotify_user)
    threads << Thread.new do
      if Faraday.get(spotify_user.avatar_url).status == FORBIDDEN
        updated_avatar_states << SpotifyService
          .new(spotify_user)
          .updated_avatar_state
      end
    end
  end

  def wait_for_requests_to_finish
    threads.each(&:join)
  end

  def update_expired_avatars
    updated_avatar_states.each do |updated_avatar_state|
      SpotifyUser
        .find(updated_avatar_state[:spotify_user_id])
        .update(avatar_url: updated_avatar_state[:avatar_url])
    end
  end
end
