class UpdateInactiveUsersPlayback
  def self.update
    UpdatePlaybackStates.update(listening: false)
  end
end
