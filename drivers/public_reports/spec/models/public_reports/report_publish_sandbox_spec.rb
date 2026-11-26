###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Publishing public reports in sandbox mode', type: :model do
  let(:user) { create(:acl_user) }

  def published(klass)
    report = klass.new(user: user, filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } }, version_slug: 'state', published_url: 'https://example.test/index.html', state: 'published')
    report.save!(validate: false)
    report
  end

  [PublicReports::PointInTime, PublicReports::HomelessPopulation, PublicReports::StateLevelHomelessness, PublicReports::StateDashboard].each do |klass|
    it "#{klass.name} skips publishing and leaves the existing published report in place" do
      first = published(klass)
      second = published(klass)
      second.update_column(:state, 'pre-calculated')

      with_sandbox_mode do
        expect { second.publish! }.not_to raise_error
      end

      expect(
        [first.reload.attributes.values_at('published_url', 'state'), second.reload.attributes.values_at('state', 'html')],
      ).to eq([['https://example.test/index.html', 'published'], ['pre-calculated', nil]])
    end
  end
end
