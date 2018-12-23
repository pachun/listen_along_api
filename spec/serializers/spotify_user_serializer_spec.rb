require "rails_helper"

describe SpotifyUserSerializer do
  it "serializes broadcasters" do
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
      "avatar_url" => nil,
    )
  end

  it "serializes avatar urls" do
    listener = create :spotify_user,
      avatar_url: "http://x.y.z.jpg"

    serializer = SpotifyUserSerializer.new(listener)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    avatar_url = JSON.parse(serialization)["avatar_url"]

    expect(avatar_url).to eq("http://x.y.z.jpg")
  end
end
