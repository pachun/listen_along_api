require "rails_helper"
require "sidekiq/testing"

Sidekiq::Testing.inline!

describe UpdateInactiveUsersPlaybackWorker, type: :worker do
  it "updates the playback of users who weren't previously listening to spotify" do
    allow(UpdateInactiveUsersPlayback).to receive(:update)

    UpdateInactiveUsersPlaybackWorker.perform_async

    expect(UpdateInactiveUsersPlayback).to have_received(:update)
  end
end
