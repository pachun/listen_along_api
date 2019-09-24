class AddSpotifyUserAndAppToSpotifyApiRateLimitHit < ActiveRecord::Migration[5.2]
  def change
    add_reference :spotify_api_rate_limit_hits, :spotify_user, foreign_key: true
    add_reference :spotify_api_rate_limit_hits, :spotify_app, foreign_key: true
  end
end
