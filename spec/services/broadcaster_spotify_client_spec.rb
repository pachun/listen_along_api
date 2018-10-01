require "rails_helper"

describe BroadcasterSpotifyClient do
  describe "#currently_playing_song_name" do
    context "the song 'Bone Dry' is playing" do
      context "the spotify access token has expired" do
        it "gets a new access token then returns the song name" do
          refreshed_access_token = "refreshed access token"

          credentials = create :spotify_credential,
            access_token: "expired token",
            refresh_token: "refresh token"

          refresh_token_request_header = Base64.urlsafe_encode64(
            "#{ENV["SPOTIFY_CLIENT_ID"]}:#{ENV["SPOTIFY_CLIENT_SECRET"]}"
          )

          stub_request(
            :get,
            "https://api.spotify.com/v1/me/player/currently-playing"
          ).with(
            headers: { "Authorization": "Bearer #{credentials.access_token}" },
          ).to_return(
            status: 401,
          )

          stub_request(
            :post,
            "https://accounts.spotify.com/api/token"
          ).with(
            body: {
              "grant_type": "refresh_token",
              "refresh_token": credentials.refresh_token,
            },
            headers: {
              "Authorization": "Basic #{refresh_token_request_header}",
              "Content-Type": "application/x-www-form-urlencoded",
            }
          ).to_return(
            status: 200,
            body: { "access_token": refreshed_access_token }.to_json,
          )

          stub_request(
            :get,
            "https://api.spotify.com/v1/me/player/currently-playing"
          ).with(
            headers: { "Authorization": "Bearer #{refreshed_access_token}" },
          ).to_return(
            status: 200,
            body: {item: { name: "Bone Dry" }}.to_json,
          )

          song_name = BroadcasterSpotifyClient.new.currently_playing_song[:name]

          expect(
            credentials.reload.access_token
          ).to eq("refreshed access token")
          expect(song_name).to eq("Bone Dry")
        end
      end

      it "returns 'Bone Dry'" do
        access_token = "token"

        stub_request(
          :get,
          "https://api.spotify.com/v1/me/player/currently-playing"
        ).with(
          headers: { "Authorization": "Bearer #{access_token}" },
        ).to_return(
          status: 200,
          body: {item: { name: "Bone Dry" }}.to_json,
        )

        create :spotify_credential,
          access_token: access_token

        expect(
          BroadcasterSpotifyClient.new.currently_playing_song[:name]
        ).to eq("Bone Dry")
      end
    end

    context "the song 'Aerials' is playing" do
      it "returns 'Aerials'" do
        access_token = "token"

        stub_request(
          :get,
          "https://api.spotify.com/v1/me/player/currently-playing"
        ).with(
          headers: { "Authorization": "Bearer #{access_token}" },
        ).to_return(
          status: 200,
          body: {item: { name: "Aerials" }}.to_json,
        )

        create :spotify_credential,
          access_token: access_token

        expect(
          BroadcasterSpotifyClient.new.currently_playing_song[:name]
        ).to eq("Aerials")
      end
    end

    context "there is no song playing" do
      it "returns 'No Song Playing'" do
        access_token = "token"

        stub_request(
          :get,
          "https://api.spotify.com/v1/me/player/currently-playing"
        ).with(
          headers: { "Authorization": "Bearer #{access_token}" },
        ).to_return(status: 204)

        create :spotify_credential,
          access_token: access_token

        expect(
          BroadcasterSpotifyClient.new.currently_playing_song[:name]
        ).to eq("No Song Playing")
      end
    end
  end
end
