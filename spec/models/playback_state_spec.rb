require "rails_helper"

describe PlaybackState do
  describe "#playback_state" do
    context "the user removed listen along permissions from their spotify dashboard" do
      it "returns a 'not listening' state" do
        api_response_double = instance_double(Faraday::Response)
        allow(api_response_double).to receive(:status).and_return(400)
        spotify_user_double = instance_double(SpotifyUser)
        playback_state = PlaybackState.new(
          api_response_double,
          spotify_user_double,
        ).playback_state

        expect(playback_state).to eq({
          is_listening: false,
          song_name: nil,
          song_uri: nil,
          millisecond_progress_into_song: nil,
          broadcaster: nil,
        })
      end
    end
  end
end
