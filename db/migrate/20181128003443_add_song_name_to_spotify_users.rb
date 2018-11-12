class AddSongNameToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :song_name, :string
  end
end
