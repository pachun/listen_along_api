class AddMaybeIntentionallyPausedToSpotifyUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spotify_users, :maybe_intentionally_paused, :bool, null: false, default: false
  end
end
