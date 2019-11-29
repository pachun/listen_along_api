class AddLastListenAlongAtToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :last_listen_along_at, :datetime
  end
end
