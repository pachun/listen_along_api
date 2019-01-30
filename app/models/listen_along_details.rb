class ListenAlongDetails < ApplicationRecord
  belongs_to :broadcaster, class_name: "SpotifyUser"
  belongs_to :listener, class_name: "SpotifyUser"
end
