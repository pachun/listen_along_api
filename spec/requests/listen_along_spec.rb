require "rails_helper"

describe "GET #index" do
  it "syncs the listener's Spotify playback with the broadcaster's" do
    broadcaster = create :spotify_user,
      username: "broadcaster"
    listener = create :spotify_user,
      username: "listener",
      listen_along_token: "1234"

    spotify_service_double = instance_double(SpotifyService)
    allow(SpotifyService).to receive(:new)
      .with(listener)
      .and_return(spotify_service_double)
    allow(spotify_service_double).to receive(:listen_along)

    get "/listen_along?broadcaster=#{broadcaster.username}&listener_token=#{listener.listen_along_token}"

    expect(spotify_service_double).to have_received(:listen_along).with(
      broadcaster: broadcaster,
    )
  end
end
