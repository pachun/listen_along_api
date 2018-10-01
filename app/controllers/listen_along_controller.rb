class ListenAlongController < ApplicationController
  def index
    ListenerSpotifyClient.new.listen_along
    head :ok
  end
end
