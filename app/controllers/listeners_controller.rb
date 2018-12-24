class ListenersController < ApiController
  def index
    render json: active_listeners,
      spotify_user: current_spotify_user
  end

  private

  def active_listeners
    SpotifyUser
      .where(is_listening: true)
      .where(broadcaster: nil)
      .order(:display_name)
  end

  def current_spotify_user
    SpotifyUser.find_by(listen_along_token: listeners_params[:token])
  end

  def listeners_params
    params.permit(:token)
  end
end
