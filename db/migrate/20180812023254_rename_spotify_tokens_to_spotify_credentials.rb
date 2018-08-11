class RenameSpotifyTokensToSpotifyCredentials < ActiveRecord::Migration[5.2]
  def change
    rename_table :spotify_tokens, :spotify_credentials
  end
end
