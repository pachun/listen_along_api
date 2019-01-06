class ListenAlongController < ApiController
  def index
    SpotifyService.new(listener).listen_along(broadcaster: broadcaster)
  end

  private

  def listener
    @listener ||= SpotifyUser.find_by(listen_along_token: listen_along_params[:listener_token])
  end

  def broadcaster
    @broadcaster ||= SpotifyUser.find_by(
      username: listen_along_params[:broadcaster]
    )
  end

  def listen_along_params
    params.permit(:listener_token, :broadcaster)
  end
end
