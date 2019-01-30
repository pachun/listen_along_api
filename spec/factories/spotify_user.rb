FactoryBot.define do
  factory :spotify_user do
    sequence :access_token do |n|
      "token_#{n}"
    end
    listen_along_token { new_token }
    spotify_app { create :spotify_app }
  end
end

def new_token
  (0...32).map { ('a'..'z').to_a[rand(26)] }.join
end
