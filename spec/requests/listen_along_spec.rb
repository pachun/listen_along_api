require "rails_helper"

describe "GET #index" do
  it "syncs the listener's Spotify playback with the broadcaster's playback" do
    broadcaster = create :spotify_user,
      username: "broadcaster"
    listener = create :spotify_user,
      username: "listener"

    spotify_service_double = instance_double(SpotifyService)
    allow(SpotifyService).to receive(:new).with(listener).and_return(spotify_service_double)
    allow(spotify_service_double).to receive(:listen_along)

    get "/listen_along?broadcaster=broadcaster&listener=listener"

    expect(spotify_service_double).to have_received(:listen_along).with(
      broadcaster: broadcaster,
    )

    expected_redirect = ENV["CLIENT_URL"] + "?broadcaster=broadcaster"

    expect(response).to redirect_to(expected_redirect)
  end
end
