class ListenersController < ApiController
  def index
    render json: active_listeners, spotify_user_token: listeners_params[:token]
  end

  private

  def active_listeners
    SpotifyUser
      .where(is_listening: true)
      .where(broadcaster: nil)
      .order(:display_name)
  end

  def listeners_params
    params.permit("token")
  end
end
