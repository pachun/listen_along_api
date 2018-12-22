require "rails_helper"

describe SpotifyUserSerializer do
  it "serializes ids" do
    broadcaster = create :spotify_user,
      username: "broadcaster",
      display_name: "Broadcaster Name"

    listener = create :spotify_user,
      username: "listener",
      display_name: "Listener Name",
      broadcaster: broadcaster

    serializer = SpotifyUserSerializer.new(listener)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    listener_json = JSON.parse(serialization)

    expect(listener_json["broadcaster"]).to eq(
      "username" => "broadcaster",
      "display_name" => "Broadcaster Name",
      "is_me" => false,
    )
  end
end
