class AddLastSongUriToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :last_song_uri, :string
  end
end
