require "rails_helper"

describe SpotifyUser do
  describe "#stop_listening_along!" do
    it "stops listening along" do
      broadcaster = create :spotify_user,
        maybe_intentionally_paused: true
      spotify_user = create :spotify_user,
        broadcaster: broadcaster

      spotify_user.stop_listening_along!

      spotify_user.reload

      expect(spotify_user.broadcaster).to eq(nil)
      expect(spotify_user.maybe_intentionally_paused).to eq(false)
    end
  end

  describe "#started_playing_music_independently?" do
    context "when the spotify user started playing music independently" do
      it "returns true" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "uri"
        spotify_user = create :spotify_user,
          song_uri: "another uri",
          broadcaster: broadcaster

        expect(spotify_user.started_playing_music_independently?).to eq(true)
      end
    end

    context "when the spotify user is listening to the same song as their broadcaster" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "uri"
        spotify_user = create :spotify_user,
          song_uri: "uri",
          broadcaster: broadcaster

        expect(spotify_user.started_playing_music_independently?).to eq(false)
      end
    end

    context "when the spotify user's broadcaster changed their song" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "another uri"
        spotify_user = create :spotify_user,
          song_uri: "different uri",
          broadcaster: broadcaster

        expect(spotify_user.started_playing_music_independently?).to eq(false)
      end
    end
  end

  describe "#intentionally_paused?" do
    context "when the user intentionally paused their music" do
      it "returns true" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "uri"
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: true,
          broadcaster: broadcaster

        expect(spotify_user.intentionally_paused?).to eq(true)
      end
    end

    context "when the spotify users .maybe_intentionally_paused flag is false" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "uri"
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: false,
          broadcaster: broadcaster

        expect(spotify_user.intentionally_paused?).to eq(false)
      end
    end

    context "when the broadcaster has started a new song" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "another uri"
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: true,
          broadcaster: broadcaster

        expect(spotify_user.intentionally_paused?).to eq(false)
      end
    end
  end

  describe "#may_have_intentionally_paused?" do
    context "when the listener may have intentionally paused" do
      it "returns true" do
        broadcaster = create :spotify_user,
          last_song_uri: "same uri",
          song_uri: "same uri"
        spotify_user = create :spotify_user,
          is_listening: false,
          maybe_intentionally_paused: false,
          broadcaster: broadcaster

        expect(spotify_user.may_have_intentionally_paused?).to eq(true)
      end
    end

    context "when the spotify user is listening to music" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "same uri",
          song_uri: "same uri"
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: false,
          broadcaster: broadcaster,
          is_listening: true

        expect(spotify_user.may_have_intentionally_paused?).to eq(false)
      end
    end
    context "when the listener's broadcaster has started a new song" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "another uri"
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: true,
          broadcaster: broadcaster

        expect(spotify_user.may_have_intentionally_paused?).to eq(false)
      end
    end

    context "when .maybe_intentionally_paused is already set to true" do
      it "returns false" do
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: true

        expect(spotify_user.may_have_intentionally_paused?).to eq(false)
      end
    end
  end
  describe "#resync_with_broadcaster!" do
    it "resyncs the listener with their broadcaster" do
      broadcaster = create :spotify_user
      spotify_user = create :spotify_user,
        broadcaster: broadcaster

      spotify_service_double = instance_double(SpotifyService)
      allow(spotify_service_double).to receive(:listen_along)
      allow(SpotifyService).to receive(:new).with(spotify_user)
        .and_return(spotify_service_double)

      spotify_user.resync_with_broadcaster!

      expect(spotify_service_double).to have_received(:listen_along)
        .with(broadcaster: broadcaster)
    end

    it "resets .maybe_intentionally_paused to false" do
      spotify_user = create :spotify_user,
        maybe_intentionally_paused: true

      spotify_service_double = instance_double(SpotifyService)
      allow(spotify_service_double).to receive(:listen_along)
      allow(SpotifyService).to(
        receive(:new).and_return(spotify_service_double)
      )

      spotify_user.resync_with_broadcaster!

      expect(spotify_user.reload.maybe_intentionally_paused).to eq(false)
    end
  end

  describe "#broadcaster_started_new_song?" do
    context "when no broadcaster exists" do
      it "returns nil" do
        spotify_user = create :spotify_user

        expect(spotify_user.broadcaster_started_new_song?).to eq(nil)
      end
    end

    context "when the broadcasters song did not change" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "uri"

        spotify_user = create :spotify_user,
          broadcaster: broadcaster

        expect(spotify_user.broadcaster_started_new_song?).to eq(false)
      end
    end

    context "when the listener is on the same song" do
      it "returns false" do
        broadcaster = create :spotify_user,
          song_uri: "uri"

        spotify_user = create :spotify_user,
          song_uri: "uri",
          broadcaster: broadcaster

        expect(spotify_user.broadcaster_started_new_song?).to eq(false)
      end
    end

    context "when the broadcasters song has changed" do
      it "returns true" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri1",
          song_uri: "uri2"

        spotify_user = create :spotify_user,
          song_uri: "not uri2",
          broadcaster: broadcaster

        expect(spotify_user.broadcaster_started_new_song?).to eq(true)
      end
    end
  end

  describe "#changed_song?" do
    context "the spotify user is listening to a different song" do
      it "returns true" do
        spotify_user = create :spotify_user,
          last_song_uri: "last song uri",
          song_uri: "current song uri"

        expect(spotify_user.changed_song?).to eq(true)
      end
    end

    context "the spotify user is listening to the same song" do
      it "returns false" do
        the_same_uri = "the same uri"
        spotify_user = create :spotify_user,
          last_song_uri: the_same_uri,
          song_uri: the_same_uri

        expect(spotify_user.changed_song?).to eq(false)
      end
    end
  end

  describe "#on_same_song_as_broadcaster?" do
    context "the spotify user has a broadcaster" do
      context "the spotify user is not listening to the same song as their broadcaster" do
        it "returns false" do
          broadcaster = create :spotify_user,
            song_uri: "a great song"
          listener = create :spotify_user,
            song_uri: "a poor song",
            broadcaster: broadcaster

          expect(listener.on_same_song_as_broadcaster?).to be(false)
        end
      end

      context "the spotify user is listening to the same song as their broadcaster" do
        it "returns true" do
          the_same_uri = "the same uri"
          broadcaster = create :spotify_user,
            song_uri: the_same_uri
          listener = create :spotify_user,
            song_uri: the_same_uri,
            broadcaster: broadcaster

          expect(listener.on_same_song_as_broadcaster?).to be(true)
        end
      end
    end

    context "the spotify user does not have a broadcaster" do
      it "returns false" do
        listener = create :spotify_user

        expect(listener.on_same_song_as_broadcaster?).to be(false)
      end
    end
  end
end
