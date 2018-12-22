require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "connects" do
    expect {
      connect "/cable"
    }.not_to raise_error
  end
end
