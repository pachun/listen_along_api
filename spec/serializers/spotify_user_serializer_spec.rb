require "rails_helper"

describe SpotifyUserSerializer do
  it "serializes users is_listening status" do
    spotify_user = create :spotify_user,
      is_listening: true

    serializer = SpotifyUserSerializer.new(spotify_user)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    is_listening = JSON.parse(serialization)["is_listening"]

    expect(is_listening).to eq(true)
  end

  it "serializes the uri of the song the user is listening to" do
    spotify_user = create :spotify_user,
      song_uri: "spotify:track:id"

    serializer = SpotifyUserSerializer.new(spotify_user)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    is_listening = JSON.parse(serialization)["song_uri"]

    expect(is_listening).to eq("spotify:track:id")
  end

  it "serializes user ids" do
    spotify_user = create :spotify_user

    serializer = SpotifyUserSerializer.new(spotify_user)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    spotify_user_id = JSON.parse(serialization)["id"]

    expect(spotify_user_id).to eq(spotify_user.id)
  end

  it "serializes avatar urls" do
    listener = create :spotify_user,
      avatar_url: "http://x.y.z.jpg"

    serializer = SpotifyUserSerializer.new(listener)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    avatar_url = JSON.parse(serialization)["avatar_url"]

    expect(avatar_url).to eq("http://x.y.z.jpg")
  end

  it "serializes spotify user's broadcasters" do
    broadcaster = create :spotify_user,
      listen_along_token: "my_token",
      song_name: "Sleep Alone",
      song_artists: ["Quinn", "Phoebe"],
      song_album_cover_url: "album_cover"
    listener = create :spotify_user,
      broadcaster: broadcaster

    serializer = SpotifyUserSerializer.new(listener)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    broadcaster_information = JSON.parse(serialization)["broadcaster"]

    expect(broadcaster_information["song_name"]).to eq("Sleep Alone")
    expect(broadcaster_information["song_album_cover_url"]).to eq("album_cover")
    expect(broadcaster_information["song_artists"]).to eq(["Quinn", "Phoebe"])
  end

  it "serializes currently playing song information" do
    listener = create :spotify_user,
      listen_along_token: "my_token",
      song_name: "Sleep Alone",
      song_artists: ["Quinn", "Phoebe"],
      song_album_cover_url: "album_cover"

    serializer = SpotifyUserSerializer.new(listener)
    serialization = ActiveModelSerializers::Adapter.create(serializer).to_json

    song_information = JSON.parse(serialization)

    expect(song_information["song_name"]).to eq("Sleep Alone")
    expect(song_information["song_album_cover_url"]).to eq("album_cover")
    expect(song_information["song_artists"]).to eq(["Quinn", "Phoebe"])
  end
end
