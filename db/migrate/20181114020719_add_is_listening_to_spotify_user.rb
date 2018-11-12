class AddIsListeningToSpotifyUser < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :is_listening, :bool, null: false, default: false
  end
end
