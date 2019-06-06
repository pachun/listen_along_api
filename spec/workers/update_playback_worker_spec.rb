require "rails_helper"
require "sidekiq/testing"

Sidekiq::Testing.inline!

describe UpdatePlaybackWorker, type: :worker do
  it "updates all spotify user's playback states" do
    allow(UpdatePlaybackService).to receive(:update)
    allow(UpdatePlaybackWorker).to receive(:perform_in)

    UpdatePlaybackWorker.new.perform

    expect(UpdatePlaybackService).to have_received(:update)
  end
end
