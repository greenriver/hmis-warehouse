###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::PreloadMissTracker do
  subject(:tracker) { described_class.new }

  let(:threshold) { described_class::THRESHOLD }

  def record_distinct(kind, count, offset: 0)
    count.times { |i| tracker.call(kind, offset + i + 1) }
  end

  it 'raises on the first distinct id past the threshold' do
    record_distinct(:client_roi, threshold)

    expect { tracker.call(:client_roi, threshold + 1) }.
      to raise_error(described_class::PreloadMissError, /client_roi/)
  end

  it 'counts a repeated id once' do
    (threshold * 2).times { tracker.call(:client_roi, 1) }
    record_distinct(:client_roi, threshold)

    expect { tracker.call(:client_roi, threshold + 1) }.
      to raise_error(described_class::PreloadMissError)
  end

  it 'counts each kind separately' do
    record_distinct(:client_roi, threshold)
    record_distinct(:client_restrictions, threshold, offset: 100)

    expect { tracker.call(:client_restrictions, 999) }.
      to raise_error(described_class::PreloadMissError, /client_restrictions/)
  end

  context 'outside development and test' do
    # THRESHOLD is set when the class loads, which is always under test, so the production value
    # is stubbed alongside Rails.env.local?.
    let(:alert_threshold) { 10 }

    before do
      stub_const('GrdaWarehouse::AuthPolicies::PreloadMissTracker::THRESHOLD', alert_threshold)
      allow(Rails.env).to receive(:local?).and_return(false)
      allow(Sentry).to receive(:capture_message)
    end

    it 'does not alert at the alert threshold' do
      record_distinct(:client_roi, alert_threshold)

      expect(Sentry).not_to have_received(:capture_message)
    end

    it 'sends one Sentry warning per kind past the alert threshold instead of raising' do
      record_distinct(:client_roi, alert_threshold + 5)

      expect(Sentry).to have_received(:capture_message).
        once.
        with(a_string_including('client_roi'), hash_including(level: :warning))
    end

    it 'groups the warning by the first app file outside the policy plumbing and attaches the backtrace' do
      frame = ->(path, label) { instance_double(Thread::Backtrace::Location, absolute_path: path, base_label: label) }
      root = Rails.root.to_s
      allow(tracker).to receive(:caller_locations).and_return(
        [
          frame.call('/usr/local/bundle/gems/memery/lib/memery.rb', 'pii_provider'),
          frame.call("#{root}/app/models/grda_warehouse/auth_policies/user_base_context.rb", 'preload_client'),
          frame.call("#{root}/app/models/user.rb", 'policy_for'),
          frame.call("#{root}/app/models/grda_warehouse/hud/client.rb", 'pii_provider'),
          frame.call("#{root}/drivers/some_report/app/views/some_report/details.haml", '_render_template'),
          frame.call("#{root}/app/controllers/some_controller.rb", 'index'),
        ],
      )

      record_distinct(:client_roi, alert_threshold + 1)

      site = 'drivers/some_report/app/views/some_report/details.haml'
      expect(Sentry).to have_received(:capture_message).with(
        anything,
        hash_including(
          fingerprint: ['preload-miss', 'client_roi', site],
          tags: { preload_miss_call_site: site },
          backtrace: array_including(a_string_including(__FILE__)),
        ),
      )
    end
  end
end
