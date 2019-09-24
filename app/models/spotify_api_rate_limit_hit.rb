class SpotifyApiRateLimitHit < ApplicationRecord
  belongs_to :spotify_app
  belongs_to :spotify_user
end
