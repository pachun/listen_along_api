class CreateSpotifyApps < ActiveRecord::Migration[5.2]
  def change
    create_table :spotify_apps do |t|
      t.string :name
      t.string :client_id
      t.string :client_secret

      t.timestamps
    end
  end
end
