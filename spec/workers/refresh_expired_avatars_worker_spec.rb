require "rails_helper"
require "sidekiq/testing"

Sidekiq::Testing.inline!

describe RefreshExpiredAvatarsWorker, type: :worker do
  it "updates all spotify user's playback states" do
    allow(RefreshExpiredAvatars).to receive(:refresh)

    RefreshExpiredAvatarsWorker.perform_async

    expect(RefreshExpiredAvatars).to have_received(:refresh)
  end
end
