class CreateSpotifyApiRateLimitHits < ActiveRecord::Migration[5.2]
  def change
    create_table :spotify_api_rate_limit_hits do |t|

      t.timestamps
    end
  end
end
