###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackgroundRenderJob do
  let(:job_class) do
    Class.new(described_class) do
      private def render_html(**)
        '<p>Rendered section</p>'
      end
    end
  end
  let(:render_id) { '3f2c9a1e-5b7d-4c8e-9f01-2a3b4c5d6e7f' }
  let(:stream) { BackgroundRenderChannel.stream_name(render_id) }
  let(:redis) { instance_double(Redis, close: nil) }
  let(:broadcasts) { [] }

  before do
    allow(Redis).to receive(:new).and_return(redis)
    allow(redis).to receive(:pubsub).with('numsub', anything) { |_, channel| [channel, 0] }
    allow(ActionCable.server).to receive(:broadcast) { |name, data| broadcasts << [name, data] }
  end

  # Answers PUBSUB NUMSUB for `channel` with each count in turn, repeating the last.
  def subscriber_counts(channel, *counts)
    allow(redis).to receive(:pubsub).with('numsub', channel).and_return(*counts.map { |count| [channel, count] })
  end

  def perform_and_time
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    job_class.new.perform(render_id)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  end

  def broadcast_html
    broadcasts.flat_map { |_, data| data.with_indifferent_access[:operations] }.map { |operation| operation.with_indifferent_access[:html] }
  end

  it 'broadcasts the rendered HTML to the render stream when the browser is subscribed' do
    subscriber_counts(stream, 1)

    perform_and_time

    expect(broadcasts.map(&:first)).to eq([stream])
    expect(broadcast_html).to eq(['<p>Rendered section</p>'])
  end

  it 'gives up within two seconds without broadcasting when no browser is subscribed' do
    elapsed = perform_and_time

    expect(elapsed).to be < 2
    expect(broadcasts).to be_empty
    expect(redis).to have_received(:close)
  end

  it 'renders when the subscription reaches Redis after the first check' do
    subscriber_counts(stream, 0, 0, 1)

    perform_and_time

    expect(broadcast_html).to eq(['<p>Rendered section</p>'])
  end

  it 'counts subscribers on the stream name with the cable channel prefix' do
    # Same shape as config/cable.yml once loaded: string keys with indifferent access.
    allow(ActionCable.server.config).to receive(:cable).and_return(
      ActiveSupport::HashWithIndifferentAccess.new(adapter: 'redis', url: 'redis://cache.example.test:6379/1', channel_prefix: 'hmis_test'),
    )
    subscriber_counts("hmis_test:#{stream}", 1)

    perform_and_time

    # Redis.new rejects string keys, and RSpec argument matching compares hashes indifferently.
    expect(Redis).to have_received(:new) do |options|
      expect(options.to_a).to eq([[:url, 'redis://cache.example.test:6379/1']])
    end
    expect(broadcast_html).to eq(['<p>Rendered section</p>'])
  end
end
