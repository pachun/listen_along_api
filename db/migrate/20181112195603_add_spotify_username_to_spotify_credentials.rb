class AddSpotifyUsernameToSpotifyCredentials < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_credentials, :spotify_username, :string, unique: true
  end
end
