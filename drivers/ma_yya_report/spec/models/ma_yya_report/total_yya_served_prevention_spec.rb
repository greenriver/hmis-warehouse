###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TotalYYAServedPrevention Integration', type: :model do
  let(:user) { create(:user) }
  let(:report) { MaYyaReport::Report.new(user_id: user.id) }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: Date.new(2024, 1, 1),
      end: Date.new(2024, 12, 31),
      enforce_one_year_range: false,
    )
  end

  before do
    allow(report).to receive(:filter).and_return(filter)
  end

  describe 'TotalYYAServedPrevention includes all four sub-populations' do
    let!(:a1b_client) do
      create(
        :ma_yya_report_client,
        :a1b,
        entry_date: Date.new(2024, 6, 1),
      )
    end

    let!(:a2b_client) do
      create(
        :ma_yya_report_client,
        :a2b,
        entry_date: Date.new(2024, 7, 1),
      )
    end

    let!(:a3a_client) do
      create(
        :ma_yya_report_client,
        :a3a,
        entry_date: Date.new(2024, 8, 1),
      )
    end

    let!(:a3b_client) do
      create(
        :ma_yya_report_client,
        :a3b,
        entry_date: Date.new(2023, 6, 1), # Before period
        latest_non_homeless_cls_in_range: Date.new(2024, 3, 15), # During period
      )
    end

    # Clients that should NOT be included
    let!(:homeless_client) do
      create(
        :ma_yya_report_client,
        :homeless,
        entry_date: Date.new(2024, 6, 1),
      )
    end

    let!(:entry_before_no_cls_client) do
      create(
        :ma_yya_report_client,
        entry_date: Date.new(2023, 6, 1), # Before period
        latest_non_homeless_cls_in_range: nil, # No CLS during period
        at_risk_of_homelessness: false,
      )
    end

    let(:calculators) { report.send(:calculators) }
    let(:total_calculation) { calculators[:TotalYYAServedPrevention] }
    let(:a1b_calculation) { report.send(:section_a1_cells)[:A1b][:calculation] }
    let(:a2b_calculation) { report.send(:section_a2_cells)[:A2b][:calculation] }
    let(:a3a_calculation) { report.send(:section_a3_cells)[:A3a][:calculation] }
    let(:a3b_calculation) { report.send(:section_a3_cells)[:A3b][:calculation] }

    describe 'A1b (Outreach referral + at-risk)' do
      it 'includes A1b clients' do
        matching_clients = MaYyaReport::Client.where(a1b_calculation)
        expect(matching_clients).to include(a1b_client)
      end

      it 'excludes non-A1b clients' do
        matching_clients = MaYyaReport::Client.where(a1b_calculation)
        expect(matching_clients).not_to include(a2b_client, a3a_client, a3b_client, homeless_client)
      end
    end

    describe 'A2b (Initial contact + at-risk)' do
      it 'includes A2b clients' do
        matching_clients = MaYyaReport::Client.where(a2b_calculation)
        expect(matching_clients).to include(a2b_client)
      end

      it 'excludes non-A2b clients' do
        matching_clients = MaYyaReport::Client.where(a2b_calculation)
        expect(matching_clients).not_to include(a1b_client, a3a_client, a3b_client, homeless_client)
      end
    end

    describe 'A3a (Entry during period + at-risk)' do
      it 'includes A3a clients' do
        matching_clients = MaYyaReport::Client.where(a3a_calculation)
        expect(matching_clients).to include(a3a_client)
      end

      it 'also includes A1b and A2b clients who entered during period' do
        # A1b and A2b clients also have at_risk and entered during period
        matching_clients = MaYyaReport::Client.where(a3a_calculation)
        expect(matching_clients).to include(a1b_client, a2b_client, a3a_client)
      end

      it 'excludes clients who entered before period' do
        matching_clients = MaYyaReport::Client.where(a3a_calculation)
        expect(matching_clients).not_to include(a3b_client)
      end
    end

    describe 'A3b (Entry before period + CLS during period)' do
      it 'includes A3b clients' do
        matching_clients = MaYyaReport::Client.where(a3b_calculation)
        expect(matching_clients).to include(a3b_client)
      end

      it 'excludes clients without CLS during period' do
        matching_clients = MaYyaReport::Client.where(a3b_calculation)
        expect(matching_clients).not_to include(entry_before_no_cls_client)
      end

      it 'excludes clients who entered during period' do
        matching_clients = MaYyaReport::Client.where(a3b_calculation)
        expect(matching_clients).not_to include(a1b_client, a2b_client, a3a_client)
      end
    end

    describe 'TotalYYAServedPrevention' do
      it 'includes all four sub-populations (A1b, A2b, A3a, A3b)' do
        matching_clients = MaYyaReport::Client.where(total_calculation)

        expect(matching_clients).to include(a1b_client), 'Should include A1b client'
        expect(matching_clients).to include(a2b_client), 'Should include A2b client'
        expect(matching_clients).to include(a3a_client), 'Should include A3a client'
        expect(matching_clients).to include(a3b_client), 'Should include A3b client'
      end

      it 'excludes homeless clients' do
        matching_clients = MaYyaReport::Client.where(total_calculation)
        expect(matching_clients).not_to include(homeless_client)
      end

      it 'excludes clients who entered before period without CLS during period' do
        matching_clients = MaYyaReport::Client.where(total_calculation)
        expect(matching_clients).not_to include(entry_before_no_cls_client)
      end

      it 'counts exactly 4 clients (unduplicated)' do
        count = MaYyaReport::Client.where(total_calculation).count
        expect(count).to eq(4), "Expected 4 clients (A1b, A2b, A3a, A3b), got #{count}"
      end
    end

    describe 'real-world scenarios' do
      context 'client with multiple characteristics' do
        let!(:multi_trait_client) do
          create(
            :ma_yya_report_client,
            entry_date: Date.new(2024, 6, 1),
            referral_source: 7, # A1b trait
            at_risk_of_homelessness: true,
            initial_contact: true, # Would also match A2b if not for referral source
            enrolled_in_street_outreach: false,
          )
        end

        it 'counts client only once in total even if matching multiple criteria' do
          # This client matches both A1b (referral 7 + at_risk) and A3a (entry during + at_risk)
          a1b_matches = MaYyaReport::Client.where(a1b_calculation)
          a3a_matches = MaYyaReport::Client.where(a3a_calculation)
          total_matches = MaYyaReport::Client.where(total_calculation)

          expect(a1b_matches).to include(multi_trait_client)
          expect(a3a_matches).to include(multi_trait_client)

          # Should only be counted once in total
          all_client_ids = [a1b_client, a2b_client, a3a_client, a3b_client, multi_trait_client].map(&:id)
          expect(total_matches.where(id: all_client_ids).count).to eq(5)
        end
      end
    end
  end
end
