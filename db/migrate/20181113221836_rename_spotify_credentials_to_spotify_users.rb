class RenameSpotifyCredentialsToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    rename_table :spotify_credentials, :spotify_users
    rename_column :spotify_users, :spotify_username, :username
  end
end
