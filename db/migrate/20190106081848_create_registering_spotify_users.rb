class CreateRegisteringSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :registering_spotify_users do |t|
      t.string :broadcaster_username
      t.string :identifier
      t.references :spotify_app, foreign_key: true

      t.timestamps
    end
  end
end
