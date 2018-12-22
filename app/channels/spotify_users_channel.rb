class SpotifyUsersChannel < ApplicationCable::Channel
  def subscribed
    stream_from "spotify_users_channel"
  end
end
