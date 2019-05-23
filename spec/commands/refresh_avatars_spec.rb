require "rails_helper"

describe RefreshExpiredAvatars do
  describe "self.refresh" do
    it "refreshes expired spotify users avatars" do
      expired_avatar_user = create :spotify_user,
        avatar_url: "https://expired_avatar_url"

      unexpired_avatar_user = create :spotify_user,
        avatar_url: "https://unexpired_avatar_url"

      requests = [
        stub_request(:get, "https://expired_avatar_url").to_return(status: 403),
        stub_request(:get, "https://unexpired_avatar_url").to_return(status: 200),
        stub_spotify_username_request(
          access_token: expired_avatar_user.access_token,
          avatar_url: "https://refreshed_avatar_url",
        ),
      ]

      RefreshExpiredAvatars.refresh

      expect(requests).to all(have_been_made)
      expect(unexpired_avatar_user.reload.avatar_url).to eq("https://unexpired_avatar_url")
      expect(expired_avatar_user.reload.avatar_url).to eq("https://refreshed_avatar_url")
    end
  end
end
