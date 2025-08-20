###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaYyaReport::Report, 'integration' do
  let(:user) { create(:user) }
  let(:report) { described_class.new(user_id: user.id) }

  describe 'integration with existing report functionality' do
    before do
      # Mock the filter to avoid complex setup
      allow(report).to receive(:filter).and_return(
        double(
          'filter',
          start: Date.new(2024, 1, 1),
          end: Date.new(2024, 12, 31),
        ),
      )
    end

    describe '#calculators integration' do
      it 'provides valid Arel calculations that can be executed' do
        calculators = report.send(:calculators)

        # Test a few sample calculations to ensure they're valid Arel queries
        expect(calculators[:A1a]).to respond_to(:to_sql)
        expect(calculators[:D1a]).to respond_to(:to_sql)
        expect(calculators[:F2a]).to respond_to(:to_sql)
      end

      it 'generates SQL for calculations without errors' do
        calculators = report.send(:calculators)

        # These should generate valid SQL without raising errors
        expect { calculators[:A1a].to_sql }.not_to raise_error
        expect { calculators[:D1a].to_sql }.not_to raise_error
        expect { calculators[:TotalYYAServedHomeless].to_sql }.not_to raise_error
      end
    end

    describe '#row_count integration' do
      it 'calculates row counts correctly for subsections' do
        # A1 subsection has 2 cells (A1a, A1b)
        expect(report.row_count('A1')).to eq(2)

        # D1 subsection has 7 cells (D1a through D1g)
        expect(report.row_count('D1')).to eq(7)

        # F2 subsection has 2 cells (F2a, F2b)
        expect(report.row_count('F2')).to eq(2)
      end
    end

    describe '#label method special cases' do
      it 'handles special label cases correctly' do
        expect(report.label(:TotalYYAServedHomeless)).to eq('Total YYA Served: Homeless/Rehousing')
        expect(report.label(:TotalYYAServedPrevention)).to eq('Total YYA Served: Prevention')
        expect(report.label(:A1a)).to eq('A1a'.underscore.titleize)
      end
    end

    describe 'title and url methods' do
      it 'returns correct title' do
        expect(report.title).to eq('MA YYA Report')
      end

      it 'generates URL correctly' do
        # Stub ENV for URL generation
        allow(ENV).to receive(:fetch).with('FQDN').and_return('example.com')
        allow(report).to receive(:id).and_return(123)

        expected_url = 'https://example.com/ma_yya_report/warehouse_reports/reports/123'
        expect(report.url).to eq(expected_url)
      end
    end

    describe 'section and subsection label integration' do
      it 'correctly maps section labels to report structure' do
        # Verify that our nested structure correctly maps to the expected output
        expect(report.section_label('A')).to eq('A. Core Services')
        expect(report.subsection_label('A1')[:text]).to eq('1. Street Outreach/Colaboration')
      end

      it 'provides comprehensive coverage of all report sections' do
        # Ensure we have labels for all the sections that might be used in views
        ['A', 'D', 'F', 'G'].each do |section|
          expect(report.section_label(section)).to be_present
        end

        ['A1', 'A2', 'A3', 'A4', 'A_Total', 'D1', 'D2', 'D3', 'D4', 'F2', 'G1', 'G2', 'G3'].each do |subsection|
          expect(report.subsection_label(subsection)[:text]).to be_present
        end
      end
    end

    describe 'performance characteristics' do
      it 'efficiently handles multiple calls to derived methods' do
        # Multiple calls should use memoization and be fast
        expect do
          10.times do
            report.send(:calculators)
            report.send(:cell_labels)
            report.section_label('A')
            report.subsection_label('A1')
          end
        end.to perform_under(100).ms
      end
    end

    describe 'data consistency across refactor' do
      it 'maintains the exact same cell keys as before refactor' do
        # This test ensures we didn't accidentally change the cell definitions during refactor
        expected_cells = [
          :A1a, :A1b, :A2a, :A2b, :A3a, :A3b, :A4a, :A4b,
          :TotalYYAServedPrevention, :TotalYYAServedHomeless,
          :D1a, :D1b, :D1c, :D1d, :D1e, :D1f, :D1g,
          :D2a, :D2b, :D2c, :D2d, :D2e, :D2f, :D2g, :D2h, :D2i, :D2j, :D2k,
          :D3a, :D3b, :D3c, :D3d,
          :D4a, :D4b, :D4c, :D4d, :D4e, :D4f, :D4g,
          :F2a, :F2b,
          :G1a, :G1b, :G1c, :G1d, :G1e, :G1f, :G1g,
          :G2a, :G2b, :G2c, :G2d, :G2e, :G2f, :G2g, :G2h,
          :G3a
        ]

        actual_cells = report.send(:calculators).keys
        expect(actual_cells).to eq(expected_cells)
        expect(actual_cells.count).to eq(57)
      end

      it 'maintains consistent section structure' do
        # Ensure the nested structure produces the same flat result as before
        nested = report.send(:nested_cell_definitions)

        # Count cells in each section
        section_a_cells = nested['A'][:subsections].values.sum { |sub| sub[:cells].keys.count }
        section_d_cells = nested['D'][:subsections].values.sum { |sub| sub[:cells].keys.count }
        section_f_cells = nested['F'][:subsections].values.sum { |sub| sub[:cells].keys.count }
        section_g_cells = nested['G'][:subsections].values.sum { |sub| sub[:cells].keys.count }

        expect(section_a_cells).to eq(10) # A1(2) + A2(2) + A3(2) + A4(2) + A_Total(2)
        expect(section_d_cells).to eq(29) # D1(7) + D2(11) + D3(4) + D4(7)
        expect(section_f_cells).to eq(2)  # F2(2)
        expect(section_g_cells).to eq(16) # G1(7) + G2(8) + G3(1)
        expect(section_a_cells + section_d_cells + section_f_cells + section_g_cells).to eq(57)
      end
    end
  end
end
