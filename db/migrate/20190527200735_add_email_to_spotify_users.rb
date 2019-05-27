class AddEmailToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :email, :string
  end
end
