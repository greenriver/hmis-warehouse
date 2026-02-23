###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaReports::MonthlyPerformance::Report, type: :model do
  let(:user) { create(:user) }
  let(:report) { described_class.new(user_id: user.id) }

  describe '.current_version' do
    it 'returns 2026' do
      expect(described_class.current_version).to eq(2026)
    end
  end

  describe '#report_version' do
    context 'when version is not set' do
      it 'defaults to 2024' do
        report.options = {}
        expect(report.report_version).to eq(2024)
      end
    end

    context 'when version is set to 2026' do
      it 'returns 2026' do
        report.options = { 'version' => 2026 }
        expect(report.report_version).to eq(2026)
      end
    end
  end

  describe '#show_gender?' do
    after do
      AppConfigProperty.find_by(key: 'show_gender_in_reports')&.destroy
    end

    context 'when version is prior to 2026' do
      it 'returns true regardless of app config' do
        report.options = {}
        expect(report.show_gender?).to be true
      end
    end

    context 'when version is 2026 or later' do
      context 'when show_gender_in_reports property is not set' do
        it 'returns false (default)' do
          report.options = { 'version' => 2026 }
          expect(report.show_gender?).to be false
        end
      end

      context 'when show_gender_in_reports property is true' do
        before do
          AppConfigProperty.create!(key: 'show_gender_in_reports', value: true)
        end

        it 'returns true' do
          report.options = { 'version' => 2026 }
          expect(report.show_gender?).to be true
        end
      end
    end
  end

  describe '#show_sex?' do
    context 'when version is not set (defaults to 2024)' do
      it 'returns false' do
        report.options = {}
        expect(report.show_sex?).to be false
      end
    end

    context 'when version is 2026' do
      it 'returns true' do
        report.options = { 'version' => 2026 }
        expect(report.show_sex?).to be true
      end
    end
  end

  describe '#demographic_breakdowns' do
    let(:mock_relation) do
      double('Relation').tap do |rel|
        allow(rel).to receive(:select).and_return(rel)
        allow(rel).to receive(:distinct).and_return(rel)
        allow(rel).to receive(:count).and_return(5)
      end
    end

    before do
      report.save!
      allow(report).to receive(:enrollments_for).and_return(mock_relation)
    end

    context 'when show_gender? is true' do
      before do
        Rails.cache.clear
        allow(report).to receive(:show_gender?).and_return(true)
        allow(report).to receive(:show_sex?).and_return(false)
      end

      it 'includes gender breakdowns' do
        breakdowns = report.demographic_breakdowns
        gender_keys = breakdowns.keys.select { |k| k.start_with?('Gender:') }
        expect(gender_keys).not_to be_empty
      end

      it 'excludes sex breakdowns' do
        breakdowns = report.demographic_breakdowns
        sex_keys = breakdowns.keys.select { |k| k.start_with?('Sex:') }
        expect(sex_keys).to be_empty
      end
    end

    context 'when show_sex? is true' do
      before do
        Rails.cache.clear
        allow(report).to receive(:show_gender?).and_return(false)
        allow(report).to receive(:show_sex?).and_return(true)
      end

      it 'includes sex breakdowns' do
        breakdowns = report.demographic_breakdowns
        sex_keys = breakdowns.keys.select { |k| k.start_with?('Sex:') }
        expect(sex_keys).not_to be_empty
        expect(sex_keys).to include('Sex: Male')
        expect(sex_keys).to include('Sex: Female')
        expect(sex_keys).to include('Sex: Unknown (Missing, Prefers not to answer, Unknown)')
      end

      it 'excludes gender breakdowns' do
        breakdowns = report.demographic_breakdowns
        gender_keys = breakdowns.keys.select { |k| k.start_with?('Gender:') }
        expect(gender_keys).to be_empty
      end
    end
  end
end
