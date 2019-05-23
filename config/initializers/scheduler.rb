require "rufus-scheduler"

EVERY_DAY_AT_MIDNIGHT = "0 0 * * *"
FIVE_SECONDS = "5s"

scheduler = Rufus::Scheduler.singleton

scheduler.every FIVE_SECONDS do
  run { UpdatePlaybackService.update }
end

scheduler.cron EVERY_DAY_AT_MIDNIGHT do
  run { RefreshExpiredAvatars.refresh }
end

def run
  begin
    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.connection.verify!
    end

    yield

  rescue => e
    Rails.logger.debug(e.inspect)
  ensure
    ActiveRecord::Base.connection_pool.release_connection
  end
end
