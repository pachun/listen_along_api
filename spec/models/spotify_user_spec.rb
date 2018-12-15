require "rails_helper"

describe SpotifyUser do
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
