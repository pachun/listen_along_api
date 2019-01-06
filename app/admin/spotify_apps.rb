ActiveAdmin.register SpotifyApp do
  permit_params :name, :client_identifier, :client_secret
end

class SpotifyApp < ApplicationRecord
  def diplay_name
    name
  end
end
