class AddIsListeningToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :is_listening, :bool
  end
end
