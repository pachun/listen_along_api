require "rails_helper"

describe SpotifyApp do
  describe ":with_most_spotify_users scope" do
    it "returns the spotify app with the most spotify users" do
      app_1 = create :spotify_app
      create :spotify_user, spotify_app: app_1

      app_2 = create :spotify_app

      expect(SpotifyApp.with_most_spotify_users).to eq(app_1)

      create :spotify_user, spotify_app: app_2
      create :spotify_user, spotify_app: app_2

      expect(SpotifyApp.with_most_spotify_users).to eq(app_2)
    end
  end

  describe "self.concurrently_updatable_user_batches(batch_size:)" do
    it "returns batches of concurrently updatable spotify users" do
      app_1 = create :spotify_app
      app_1_users = (0..4).map { create :spotify_user, spotify_app: app_1 }

      app_2 = create :spotify_app
      app_2_users = (0..1).map { create :spotify_user, spotify_app: app_2 }

      create :spotify_app

      batches = SpotifyApp
        .concurrently_updatable_spotify_user_batches(batch_size: 2)

      expect(batches).to eq([[
        app_1_users[0], app_2_users[0],
      ], [
        app_1_users[1], app_2_users[1],
      ], [
        app_1_users[2], app_1_users[3],
      ], [
        app_1_users[4],
      ]])
    end
  end
end
