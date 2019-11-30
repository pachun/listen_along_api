class RefreshExpiredAvatarsWorker
  include Sidekiq::Worker

  def perform
    RefreshExpiredAvatars.refresh
  end
end
