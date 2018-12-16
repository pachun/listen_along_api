class AddListenAlongTokenToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :listen_along_token, :string
  end
end
