class AddMillisecondProgressIntoSongToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :millisecond_progress_into_song, :string
  end
end
