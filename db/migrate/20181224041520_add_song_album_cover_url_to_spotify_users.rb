class AddSongAlbumCoverUrlToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :song_album_cover_url, :string
  end
end
