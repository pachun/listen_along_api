class RemoveIsListeningFromSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :spotify_users, :is_listening
  end
end
