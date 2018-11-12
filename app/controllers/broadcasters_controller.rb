class BroadcastersController < ApiController
  def index
    render json: SpotifyUser.where(is_listening: true).pluck(:username)
  end
end
