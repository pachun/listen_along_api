require "rails_helper"

describe SpotifyApp do
  describe ":with_most_spotify_users(listening) scope" do
    context "listening is true" do
      it "returns the spotify app with the most listening spotify users" do
        app_1 = create :spotify_app
        create :spotify_user, spotify_app: app_1, is_listening: true

        app_2 = create :spotify_app

        expect(SpotifyApp.with_most_spotify_users(listening: true)).to eq(app_1)

        create :spotify_user, spotify_app: app_2, is_listening: true
        create :spotify_user, spotify_app: app_2, is_listening: true

        expect(SpotifyApp.with_most_spotify_users(listening: true)).to eq(app_2)

        create :spotify_user, spotify_app: app_1, is_listening: false
        create :spotify_user, spotify_app: app_1, is_listening: false

        expect(SpotifyApp.with_most_spotify_users(listening: true)).to eq(app_2)
      end
    end

    context "listening is false" do
      it "returns the spotify app with the most inactive spotify users" do
        app_1 = create :spotify_app
        create :spotify_user, spotify_app: app_1, is_listening: false

        app_2 = create :spotify_app

        expect(SpotifyApp.with_most_spotify_users(listening: false)).to eq(app_1)

        create :spotify_user, spotify_app: app_2, is_listening: false
        create :spotify_user, spotify_app: app_2, is_listening: false

        expect(SpotifyApp.with_most_spotify_users(listening: false)).to eq(app_2)

        create :spotify_user, spotify_app: app_1, is_listening: true
        create :spotify_user, spotify_app: app_1, is_listening: true

        expect(SpotifyApp.with_most_spotify_users(listening: false)).to eq(app_2)
      end
    end
  end
end
