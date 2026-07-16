###
# Copyright Green River Data Group, Inc.
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

        # F1 subsection has 5 cells (F1a through F1e)
        expect(report.row_count('F1')).to eq(5)

        # F2 subsection has 5 cells (F2a through F2e)
        expect(report.row_count('F2')).to eq(5)

        # E1 subsection has 7 cells (E1a through E1g)
        expect(report.row_count('E1')).to eq(7)
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
        expect(report.section_label('D')).to eq('D. Prevention Demographics')
        expect(report.section_label('E')).to eq('E. Homeless/rehousing Demographics')
        expect(report.subsection_label('A1')[:text]).to eq('1. Street Outreach/Collaboration')
        expect(report.subsection_label('F1')[:text]).to eq('1. Prevention / Diversion/ Problem Solving Outcomes (Follow up)')
      end

      it 'provides comprehensive coverage of all report sections' do
        # Ensure we have labels for all the sections that might be used in views
        ['A', 'D', 'E', 'F', 'G', 'H'].each do |section|
          expect(report.section_label(section)).to be_present
        end

        ['A1', 'A2', 'A3', 'A4', 'A_Total', 'D1', 'D2', 'D3', 'D4', 'E1', 'E2', 'E3', 'E4', 'F1', 'F2', 'G1', 'G2', 'G3', 'H1', 'H2', 'H3'].each do |subsection|
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

    describe 'A5 Direct Financial Assistance (Flex Funds) section' do
      context 'when show_flex_funds? is false (service type or CDED absent)' do
        before { allow(report).to receive(:show_flex_funds?).and_return(false) }

        it 'excludes A5 from section_a_subsections' do
          expect(report.send(:section_a_subsections).keys).not_to include('A5')
        end

        it 'section A has 10 cells without A5' do
          nested = report.send(:nested_cell_definitions)
          section_a_cells = nested['A'][:subsections].values.sum { |sub| sub[:cells].keys.count }
          expect(section_a_cells).to eq(10)
        end
      end

      context 'when show_flex_funds? is true (CustomServiceType "Flex Funds" and flex_funds_types CDED exist)' do
        before { allow(report).to receive(:show_flex_funds?).and_return(true) }

        it 'includes A5 in section_a_subsections' do
          expect(report.send(:section_a_subsections).keys).to include('A5')
        end

        it 'A5 has 14 cells (A5a through A5n)' do
          cells = report.send(:section_a5_cells)
          expect(cells.keys).to eq([:A5a, :A5b, :A5c, :A5d, :A5e, :A5f, :A5g, :A5h, :A5i, :A5j, :A5k, :A5l, :A5m, :A5n])
        end

        it 'section A has 24 cells when A5 is present' do
          nested = report.send(:nested_cell_definitions)
          section_a_cells = nested['A'][:subsections].values.sum { |sub| sub[:cells].keys.count }
          expect(section_a_cells).to eq(24)
        end

        it 'A5a counts clients where direct_assistance = true' do
          sql = report.send(:section_a5_cells)[:A5a][:calculation].to_sql
          expect(sql).to include('"direct_assistance" = TRUE')
        end

        it 'A5f (Transportation) uses a case-insensitive JSON array match on the stripped type name' do
          # The universe calculator strips parenthesized text, so "Transportation (bus pass)" → "Transportation".
          # json_contains_text lower-cases both sides so "Transportation" is matched as "transportation".
          sql = report.send(:section_a5_cells)[:A5f][:calculation].to_sql
          expect(sql).to include('lower(flex_funds')
          expect(sql).to include("? 'transportation'")
        end

        it 'A5i (Child care) matches the exact stripped type string' do
          sql = report.send(:section_a5_cells)[:A5i][:calculation].to_sql
          expect(sql).to include("? 'child care'")
        end

        it 'A5c (Rent) matches the stripped type — "Rent (Direct Financial Assistance)" strips to "Rent"' do
          sql = report.send(:section_a5_cells)[:A5c][:calculation].to_sql
          # Must match "rent" (the stripped, lowercased value), not "rent (direct financial assistance)"
          expect(sql).to include("? 'rent'")
          expect(sql).not_to include('direct financial assistance')
        end

        it 'all A5b–A5n cells also require direct_assistance = true' do
          cells = report.send(:section_a5_cells)
          cells.except(:A5a).each do |key, defn|
            expect(defn[:calculation].to_sql).to(
              include('"direct_assistance" = TRUE'),
              "Expected #{key} to require direct_assistance = true",
            )
          end
        end
      end
    end

    describe 'data consistency across refactor' do
      it 'maintains the expected cell keys structure' do
        # This test ensures the cell structure is as expected after updates
        expected_cells = [
          :A1a, :A1b, :A2a, :A2b, :A3a, :A3b, :A4a, :A4b,
          :TotalYYAServedPrevention, :TotalYYAServedHomeless,
          :D1a, :D1b, :D1c, :D1d, :D1e, :D1f, :D1g,
          :D2a, :D2b, :D2c, :D2d, :D2e, :D2f, :D2g, :D2h, :D2i, :D2j, :D2k,
          :D3a, :D3b, :D3c, :D3d,
          :D4a, :D4b, :D4c, :D4d, :D4e, :D4f, :D4g, :D4h, :D4i, :D4j, :D4k, :D4l,
          :E1a, :E1b, :E1c, :E1d, :E1e, :E1f, :E1g,
          :E2a, :E2b, :E2c, :E2d, :E2e, :E2f, :E2g, :E2h, :E2i, :E2j, :E2k,
          :E3a, :E3b, :E3c, :E3d,
          :E4a, :E4b, :E4c, :E4d, :E4e, :E4f, :E4g, :E4h, :E4i, :E4j, :E4k, :E4l,
          :F1a, :F1b, :F1c, :F1d, :F1e,
          :F2a, :F2b, :F2c, :F2d, :F2e,
          :G1a, :G1b, :G1c, :G1d, :G1e, :G1f, :G1g,
          :G2a, :G2b, :G2c, :G2d, :G2e, :G2f, :G2g, :G2h,
          :G3a,
          :H1a, :H1b, :H1c, :H1d, :H1e, :H1f, :H1g,
          :H2a, :H2b, :H2c, :H2d, :H2e, :H2f, :H2g, :H2h,
          :H3a
        ]

        actual_cells = report.send(:calculators).keys
        expect(actual_cells).to eq(expected_cells)
        expect(actual_cells.count).to eq(120)
      end

      it 'maintains consistent section structure' do
        # Ensure the nested structure produces the expected flat result
        nested = report.send(:nested_cell_definitions)

        # Count cells in each section
        section_a_cells = nested['A'][:subsections].values.sum { |sub| sub[:cells].keys.count }
        section_d_cells = nested['D'][:subsections].values.sum { |sub| sub[:cells].keys.count }
        section_e_cells = nested['E'][:subsections].values.sum { |sub| sub[:cells].keys.count }
        section_f_cells = nested['F'][:subsections].values.sum { |sub| sub[:cells].keys.count }
        section_g_cells = nested['G'][:subsections].values.sum { |sub| sub[:cells].keys.count }
        section_h_cells = nested['H'][:subsections].values.sum { |sub| sub[:cells].keys.count }

        expect(section_a_cells).to eq(10) # A1(2) + A2(2) + A3(2) + A4(2) + A_Total(2)
        expect(section_d_cells).to eq(34) # D1(7) + D2(11) + D3(4) + D4(12)
        expect(section_e_cells).to eq(34) # E1(7) + E2(11) + E3(4) + E4(12)
        expect(section_f_cells).to eq(10) # F1(5) + F2(5)
        expect(section_g_cells).to eq(16) # G1(7) + G2(8) + G3(1)
        expect(section_h_cells).to eq(16) # H1(7) + H2(8) + H3(1)
        expect(section_a_cells + section_d_cells + section_e_cells + section_f_cells + section_g_cells + section_h_cells).to eq(120)
      end
    end
  end
end
