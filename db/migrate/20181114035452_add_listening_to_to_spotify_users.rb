class AddListeningToToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_reference :spotify_users, :spotify_user, foreign_key: true
  end
end
