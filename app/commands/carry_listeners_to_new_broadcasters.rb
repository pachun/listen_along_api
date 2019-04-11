class CarryListenersToNewBroadcasters
  def self.carry
    new.carry
  end

  def carry
    broadcasters_who_started_listening_to_someone.each do |old_broadcaster|
      move_listeners_to_new_broadcaster(old_broadcaster)
    end
  end

  private

  def broadcasters_who_started_listening_to_someone
    SpotifyUser.joins(:listeners).where.not(broadcaster: nil)
  end

  def move_listeners_to_new_broadcaster(old_broadcaster)
    old_broadcaster.listeners.update_all(
      spotify_user_id: old_broadcaster.broadcaster.id
    )
  end
end
