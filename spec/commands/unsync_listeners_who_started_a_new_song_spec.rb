require "rails_helper"

describe UnsyncListenersWhoStartedANewSong do
  describe "self.unsync" do
    context "a listener changes their song" do
      it "stops syncing them with their broadcaster" do
        broadcasted_uri = "spotify:track:1S4FHBl24uLTzJ37VMBjut"
        a_different_uri = "spotify:track:1xyt3kmjrV3o9kbiAdwdXb"

        broadcaster = create :spotify_user,
          is_listening: true,
          song_name: "Beam Me Up",
          last_song_uri: broadcasted_uri,
          song_uri: broadcasted_uri,
          millisecond_progress_into_song: "10000"

        listener_who_played_new_song = create :spotify_user,
          is_listening: true,
          song_uri: a_different_uri,
          broadcaster: broadcaster

        stub_turn_off_repeat_request(listener_who_played_new_song)

        UnsyncListenersWhoStartedANewSong.unsync

        expect(
          listener_who_played_new_song.reload.broadcaster
        ).not_to be_present
      end
    end
  end
end
