class ListenAlongController < ApiController
  def index
    SpotifyService.new(listener).listen_along(broadcaster: broadcaster)
    redirect_to client if authenticating?
  end

  private

  def authenticating?
    listen_along_params[:authenticating].present?
  end

  def listener
    @listener ||= SpotifyUser.find_by(listen_along_token: listen_along_params[:listener_token])
  end

  def broadcaster
    @broadcaster ||= SpotifyUser.find_by(
      username: listen_along_params[:broadcaster]
    )
  end

  def client
    ENV["CLIENT_URL"] + "?token=#{listener.listen_along_token}"
  end

  def listen_along_params
    params.permit(:listener_token, :broadcaster, :authenticating)
  end
end
