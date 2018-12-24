class AddSongArtistsToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :song_artists, :string, array: true, default: []
  end
end
