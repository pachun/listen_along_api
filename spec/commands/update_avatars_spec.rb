require "rails_helper"

describe UpdateAvatars do
  it "updates users avatars" do
    not_found_avatar_user = create :spotify_user,
      avatar_url: "https://not_found_avatar_url",
      email: "hello@email.com"

    found_avatar_user = create :spotify_user,
      avatar_url: "https://found_avatar_url"

    requests = [
      stub_request(:get, "https://not_found_avatar_url").to_return(status: 404),
      stub_request(:get, "https://found_avatar_url").to_return(status: 200),
    ]

    email_hash = Digest::MD5.hexdigest(not_found_avatar_user.email)
    updated_avatar_url = \
      "https://www.gravatar.com/avatar/#{email_hash}?d=robohash&size=400"

    UpdateAvatars.update

    expect(requests).to all(have_been_made)
    expect(found_avatar_user.reload.avatar_url).to(
      eq("https://found_avatar_url")
    )
    expect(not_found_avatar_user.reload.avatar_url).to(
      eq(updated_avatar_url)
    )
  end
end
