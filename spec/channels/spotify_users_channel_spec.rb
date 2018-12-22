require "rails_helper"

RSpec.describe SpotifyUsersChannel, type: :channel do
  it "connects and streams" do
    subscribe

    expect(subscription).to be_confirmed
    expect(streams).to eq(["spotify_users_channel"])
  end
end
