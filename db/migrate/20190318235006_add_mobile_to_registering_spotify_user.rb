class AddMobileToRegisteringSpotifyUser < ActiveRecord::Migration[5.2]
  def change
    add_column :registering_spotify_users, :mobile, :boolean
  end
end
