###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'action_cable/subscription_adapter/redis'

RSpec.describe BackgroundRenderJob do
  let(:job_class) do
    Class.new(described_class) do
      private def render_html(**)
        '<p>Rendered section</p>'
      end
    end
  end
  let(:job) { job_class.new }
  let(:render_id) { '3f2c9a1e-5b7d-4c8e-9f01-2a3b4c5d6e7f' }
  let(:stream) { BackgroundRenderChannel.stream_name(render_id) }
  let(:broadcasts) { [] }
  let(:slept) { [] }

  before do
    allow(ActionCable.server).to receive(:broadcast) { |name, data| broadcasts << [name, data] }
    allow(job).to receive(:sleep) { |seconds| slept << seconds }
    allow(job).to receive(:monotonic_now) { slept.sum }
  end

  def broadcast_html
    broadcasts.flat_map { |_, data| data.with_indifferent_access[:operations] }.map { |operation| operation.with_indifferent_access[:html] }
  end

  context 'with the Redis subscription adapter' do
    let(:redis) { instance_double(Redis, close: nil) }
    let(:pubsub) { ActionCable::SubscriptionAdapter::Redis.new(ActionCable.server) }

    before do
      allow(ActionCable.server).to receive(:pubsub).and_return(pubsub)
      allow(ActionCable::SubscriptionAdapter::Redis).to receive(:redis_connector).and_return(->(_config) { redis })
      allow(redis).to receive(:pubsub).with('numsub', anything) { |_, channel| [channel, 0] }
    end

    # Answers PUBSUB NUMSUB for `channel` with each count in turn, repeating the last.
    def subscriber_counts(channel, *counts)
      allow(redis).to receive(:pubsub).with('numsub', channel).and_return(*counts.map { |count| [channel, count] })
    end

    it 'broadcasts the rendered HTML to the render stream when the browser is subscribed' do
      subscriber_counts(stream, 1)

      job.perform(render_id)

      expect(broadcasts.map(&:first)).to eq([stream])
      expect(broadcast_html).to eq(['<p>Rendered section</p>'])
    end

    it 'checks for a subscriber across one second, then skips the render' do
      job.perform(render_id)

      expect(slept.sum).to be_within(0.001).of(1)
      # One check before the first sleep and one after each sleep.
      expect(redis).to have_received(:pubsub).with('numsub', stream).exactly(slept.size + 1).times
      expect(broadcasts).to be_empty
      expect(redis).to have_received(:close)
    end

    it 'renders when the subscription reaches Redis after the first check' do
      subscriber_counts(stream, 0, 0, 1)

      job.perform(render_id)

      expect(broadcast_html).to eq(['<p>Rendered section</p>'])
    end

    it 'counts subscribers on the channel name the Redis adapter subscribes to' do
      # Same shape as config/cable.yml once loaded: string keys with indifferent access.
      allow(ActionCable.server.config).to receive(:cable).and_return(
        ActiveSupport::HashWithIndifferentAccess.new(adapter: 'redis', url: 'redis://cache.example.test:6379/1', channel_prefix: 'hmis_test'),
      )
      # channel_with_prefix is private in ActionCable; the job builds the same name itself.
      subscribed_channel = pubsub.send(:channel_with_prefix, stream)
      expect(subscribed_channel).to start_with('hmis_test')
      subscriber_counts(subscribed_channel, 1)

      job.perform(render_id)

      expect(broadcast_html).to eq(['<p>Rendered section</p>'])
    end
  end

  it 'renders without checking for a subscriber under the async adapter' do
    expect(ActionCable.server.pubsub).to be_a(ActionCable::SubscriptionAdapter::Async)

    job.perform(render_id)

    expect(broadcast_html).to eq(['<p>Rendered section</p>'])
    expect(slept).to be_empty
  end
end
