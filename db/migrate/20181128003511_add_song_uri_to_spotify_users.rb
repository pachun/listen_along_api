class AddSongUriToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :song_uri, :string
  end
end
