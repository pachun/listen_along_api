require "rails_helper"
require "sidekiq/testing"

Sidekiq::Testing.inline!

describe UpdateAvatarsWorker, type: :worker do
  it "updates all spotify user's playback states" do
    allow(UpdateAvatars).to receive(:update)

    UpdateAvatarsWorker.perform_async

    expect(UpdateAvatars).to have_received(:update)
  end
end
