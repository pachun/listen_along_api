class ListenersController < ApiController
  def index
    render json: broadcasters
  end

  private

  def broadcasters
    SpotifyUser.where(is_listening: true).order(:username).map do |spotify_user|
      {
        username: spotify_user.username,
        broadcaster: spotify_user&.broadcaster&.username,
        is_me: spotify_user.listen_along_token == listeners_params[:token],
      }
    end
  end

  def listeners_params
    params.permit("token")
  end
end
