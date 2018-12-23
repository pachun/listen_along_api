require "rails_helper"

describe SpotifyUserSerializer do
  it "serializes avatar urls" do
    listener = create :spotify_user,
      avatar_url: "http://x.y.z.jpg"

    serializer = SpotifyUserSerializer.new(listener)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    avatar_url = JSON.parse(serialization)["avatar_url"]

    expect(avatar_url).to eq("http://x.y.z.jpg")
  end

  it "serializers the number of people listening along" do
    broadcaster = create :spotify_user

    serializer = SpotifyUserSerializer.new(broadcaster)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    number_of_listeners = JSON.parse(serialization)["number_of_listeners"]

    expect(number_of_listeners).to eq(0)

    create :spotify_user,
      broadcaster: broadcaster

    serializer = SpotifyUserSerializer.new(broadcaster)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    number_of_listeners = JSON.parse(serialization)["number_of_listeners"]

    expect(number_of_listeners).to eq(1)
  end
end
