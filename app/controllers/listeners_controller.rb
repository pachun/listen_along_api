class ListenersController < ApiController
  def index
    render json: broadcasters
  end

  private

  def broadcasters
    active_listeners.map do |spotify_user|
      {
        username: spotify_user.username,
        broadcaster: spotify_user&.broadcaster&.username,
        is_me: spotify_user.listen_along_token == listeners_params[:token],
      }
    end
  end

  def active_listeners
    SpotifyUser
      .where(is_listening: true)
      .or(SpotifyUser.where.not(broadcaster: nil))
      .order(:username)
  end

  def listeners_params
    params.permit("token")
  end
end
