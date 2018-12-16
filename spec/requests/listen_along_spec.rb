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

  context "the user is not authenticating for the first time" do
    it "does not redirect back to the front end" do
      broadcaster = create :spotify_user,
        username: "broadcaster",
        listen_along_token: "5678"
      listener = create :spotify_user,
        username: "listener",
        listen_along_token: "1234"

      spotify_service_double = instance_double(SpotifyService)
      allow(SpotifyService).to receive(:new)
        .with(listener)
        .and_return(spotify_service_double)
      allow(spotify_service_double).to receive(:listen_along)

      get "/listen_along?broadcaster=#{broadcaster.username}&listener_token=#{listener.listen_along_token}"

      authenticating_redirect = ENV["CLIENT_URL"] + \
        "?broadcaster=#{broadcaster.username}&token=#{broadcaster.listen_along_token}"

      expect(response).not_to redirect_to(authenticating_redirect)
    end
  end

  context "the user is authenticating for the first time" do
    it "redirects back to the front end" do
      broadcaster = create :spotify_user,
        username: "broadcaster",
        listen_along_token: "5678"
      listener = create :spotify_user,
        username: "listener",
        listen_along_token: "1234"

      spotify_service_double = instance_double(SpotifyService)
      allow(SpotifyService).to receive(:new)
        .with(listener)
        .and_return(spotify_service_double)
      allow(spotify_service_double).to receive(:listen_along)

      get "/listen_along?broadcaster=#{broadcaster.username}&listener_token=#{listener.listen_along_token}&authenticating=true"

      authenticating_redirect = ENV["CLIENT_URL"] + \
        "?broadcaster=#{broadcaster.username}&token=#{listener.listen_along_token}"

      expect(response).to redirect_to(authenticating_redirect)
    end
  end
end
