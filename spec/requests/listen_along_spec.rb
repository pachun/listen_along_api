require "rails_helper"

describe "GET #index" do
  it "syncs pachun91's Spotify playback with ListenWithDude's" do
    listener_double = instance_double(ListenerSpotifyClient)
    allow(listener_double).to receive(:listen_along)
    allow(ListenerSpotifyClient).to receive(:new).and_return(listener_double)

    get "/listen_along"

    expect(listener_double).to have_received(:listen_along)
    expect(response).to have_http_status(:ok)
  end
end
