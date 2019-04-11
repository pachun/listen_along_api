class UpdatePlaybackStates
  def self.update
    new.update
  end

  def update
    SpotifyUser.all.each do |spotify_user|
      spotify_user.update_playback_state
    end
  end
end
