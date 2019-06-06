class UpdatePlaybackWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UpdatePlaybackService.update
  end
end
