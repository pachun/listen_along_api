class CreateSpotifyTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :spotify_tokens do |t|
      t.string :access_token
      t.string :refresh_token

      t.timestamps
    end
  end
end
