class TestChannel < ApplicationCable::Channel
  def subscribed
    stream_from "test"
  end

  def unsubscribed
  end
end
