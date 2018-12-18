FactoryBot.define do
  factory :spotify_user do
    listen_along_token { new_token }
  end
end

def new_token
  (0...32).map { ('a'..'z').to_a[rand(26)] }.join
end
