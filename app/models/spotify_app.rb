class SpotifyApp < ApplicationRecord
  has_many :spotify_users

  def self.with_most_spotify_users(listening:)
    most_users = 0
    with_most_users = nil
    SpotifyApp.all.each do |spotify_app|
      num_users = spotify_app.spotify_users.where(is_listening: listening).count
      if num_users > most_users
        most_users = num_users
        with_most_users = spotify_app
      end
    end
    with_most_users
  end
end
