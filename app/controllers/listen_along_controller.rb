class ListenAlongController < ApiController
  def index
    LoggerService.log_listen_along(
      listener: listener,
      broadcaster: broadcaster,
    )
    SpotifyService.new(listener).listen_along(broadcaster: broadcaster)
    redirect_to listening_along
  end

  private

  def listener
    @listener ||= SpotifyUser.find_by(username: listen_along_params[:listener])
  end

  def broadcaster
    @broadcaster ||= SpotifyUser.find_by(
      username: listen_along_params[:broadcaster]
    )
  end

  def listening_along
    ENV["CLIENT_URL"] + "?broadcaster=#{broadcaster.username}"
  end

  def listen_along_params
    params.permit(:listener, :broadcaster)
  end
end
