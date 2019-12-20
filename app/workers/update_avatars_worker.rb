class UpdateAvatarsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UpdateAvatars.update
  end
end
