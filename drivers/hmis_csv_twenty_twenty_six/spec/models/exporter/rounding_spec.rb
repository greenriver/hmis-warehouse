###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    ExportHelper2026.setup_data

    # Assign distinct TotalMonthlyIncome values for format testing.
    # Rows appear in the CSV in insertion order (by id); indices match FactoryBot creation order.
    ExportHelper2026.income_benefits[0].update(TotalMonthlyIncome: 0.009)
    ExportHelper2026.income_benefits[1].update(TotalMonthlyIncome: 50)
    ExportHelper2026.income_benefits[2].update(TotalMonthlyIncome: 18.5)

    # Assign distinct FAAmount values for format testing (same ordering assumption as above)
    ExportHelper2026.services[0].update(FAAmount: 100)
    ExportHelper2026.services[1].update(FAAmount: 25.5)

    @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: ExportHelper2026.projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: ExportHelper2026.user.id,
    )
    ExportHelper2026.instance_variable_set(:@exporter, @exporter)
    @exporter.export!(cleanup: false, zip: false, upload: false)

    @income_csv = CSV.read(
      ExportHelper2026.csv_file_path(ExportHelper2026.income_benefit_class),
      headers: true,
    )
    @service_csv = CSV.read(
      ExportHelper2026.csv_file_path('Services'),
      headers: true,
    )
  end

  after(:all) do
    ExportHelper2026.cleanup
  end

  describe 'IncomeBenefits.TotalMonthlyIncome formatting' do
    # Regression guard: this case already passed before the fix
    it "rounds 0.009 to '0.01'" do
      row = @income_csv.find { |r| r['TotalMonthlyIncome'].to_f.between?(0.005, 0.015) }
      expect(row).not_to be_nil
      expect(row['TotalMonthlyIncome']).to eq '0.01'
    end

    it "formats round integer 50 as '50.00'" do
      row = @income_csv.find { |r| r['TotalMonthlyIncome'].to_f.between?(49.9, 50.1) }
      expect(row).not_to be_nil
      expect(row['TotalMonthlyIncome']).to eq '50.00'
    end

    it "formats single-decimal 18.5 as '18.50'" do
      row = @income_csv.find { |r| r['TotalMonthlyIncome'].to_f.between?(18.4, 18.6) }
      expect(row).not_to be_nil
      expect(row['TotalMonthlyIncome']).to eq '18.50'
    end
  end

  describe 'Services.FAAmount formatting' do
    it "formats round integer 100 as '100.00'" do
      row = @service_csv.find { |r| r['FAAmount'].to_f.between?(99.9, 100.1) }
      expect(row).not_to be_nil
      expect(row['FAAmount']).to eq '100.00'
    end

    it "formats single-decimal 25.5 as '25.50'" do
      row = @service_csv.find { |r| r['FAAmount'].to_f.between?(25.4, 25.6) }
      expect(row).not_to be_nil
      expect(row['FAAmount']).to eq '25.50'
    end
  end

  describe '.round_value money formatting' do
    let(:klass) { HmisCsvTwentyTwentySix::Exporter::IncomeBenefit }

    it 'returns a two-decimal string for a round integer' do
      row = { TotalMonthlyIncome: 50 }
      klass.round_value(row, hud_field: :TotalMonthlyIncome, rounding: :money, positive: false)
      expect(row[:TotalMonthlyIncome]).to eq '50.00'
    end

    it 'returns a two-decimal string for a single-decimal value' do
      row = { TotalMonthlyIncome: 18.5 }
      klass.round_value(row, hud_field: :TotalMonthlyIncome, rounding: :money, positive: false)
      expect(row[:TotalMonthlyIncome]).to eq '18.50'
    end

    it 'rounds sub-cent values up and returns a string' do
      row = { TotalMonthlyIncome: 0.009 }
      klass.round_value(row, hud_field: :TotalMonthlyIncome, rounding: :money, positive: false)
      expect(row[:TotalMonthlyIncome]).to eq '0.01'
    end

    it 'returns nil for a zero value when positive: true' do
      row = { TotalMonthlyIncome: 0 }
      klass.round_value(row, hud_field: :TotalMonthlyIncome, rounding: :money, positive: true)
      expect(row[:TotalMonthlyIncome]).to be_nil
    end

    it 'returns a two-decimal string for a positive value when positive: true' do
      row = { TotalMonthlyIncome: 25.5 }
      klass.round_value(row, hud_field: :TotalMonthlyIncome, rounding: :money, positive: true)
      expect(row[:TotalMonthlyIncome]).to eq '25.50'
    end
  end
end
