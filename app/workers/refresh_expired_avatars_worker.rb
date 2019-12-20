class RefreshExpiredAvatarsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    RefreshExpiredAvatars.refresh
  end
end
