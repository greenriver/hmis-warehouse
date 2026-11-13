###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BostonProjectScorecard::ScorecardMailer, type: :mailer do
  before(:all) do
    cleanup_test_environment
  end

  after(:all) do
    cleanup_test_environment
  end

  let(:user) { create :user }
  let(:secondary_reviewer) { create :user }
  let(:data_source) { create :grda_warehouse_data_source }
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:project) do
    create(
      :hud_project,
      data_source: data_source,
      organization: organization,
      project_type: 13,
    )
  end

  let(:report) do
    BostonProjectScorecard::Report.create!(
      user: user,
      project: project,
      start_date: Date.new(2024, 10, 1),
      end_date: Date.new(2025, 9, 30),
      period_start_date: Date.new(2024, 10, 1),
      period_end_date: Date.new(2025, 9, 30),
      secondary_reviewer: secondary_reviewer,
    )
  end

  describe '#scorecard_ready' do
    it 'sends the email to the secondary reviewer' do
      mail = described_class.scorecard_ready(report).deliver_now
      expect(mail.to).to eq([secondary_reviewer.email])
    end

    context 'when the report has no secondary reviewer' do
      let(:secondary_reviewer) { nil }

      it 'raises, since callers are expected to guard against a missing secondary reviewer' do
        expect { described_class.scorecard_ready(report).deliver_now }.to raise_error(NoMethodError)
      end
    end
  end
end
