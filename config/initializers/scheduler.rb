require "rufus-scheduler"

EVERY_DAY_AT_MIDNIGHT = "0 0 * * *"

SEVEN_SECONDS = "7s"

scheduler = Rufus::Scheduler.singleton

scheduler.every SEVEN_SECONDS do
  run { UpdatePlaybackWorker.perform_async }
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
