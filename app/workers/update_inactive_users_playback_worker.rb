class UpdateInactiveUsersPlaybackWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UpdateInactiveUsersPlayback.update
  end
end
