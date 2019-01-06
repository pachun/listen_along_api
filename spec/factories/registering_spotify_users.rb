FactoryBot.define do
  factory :registering_spotify_user do
    spotify_app { create :spotify_app }
  end
end
