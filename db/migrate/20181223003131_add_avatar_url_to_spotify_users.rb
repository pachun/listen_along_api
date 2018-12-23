class AddAvatarUrlToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :avatar_url, :string
  end
end
