###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaYyaReport::Report do
  let(:user) { create(:user) }
  let(:report) { described_class.new(user_id: user.id) }

  describe 'nested cell definitions structure' do
    describe '#nested_cell_definitions' do
      let(:nested_definitions) { report.send(:nested_cell_definitions) }

      it 'returns a properly structured hash with all required sections' do
        expect(nested_definitions).to be_a(Hash)
        expect(nested_definitions.keys).to contain_exactly('A', 'D', 'E', 'F', 'G', 'H')
      end

      it 'contains section labels for each section' do
        nested_definitions.each do |section_key, section_data|
          expect(section_data).to have_key(:section_label)
          expect(section_data[:section_label]).to be_a(String)
          expect(section_data[:section_label]).to include(section_key)
        end
      end

      it 'contains subsections for each section' do
        nested_definitions.each do |_section_key, section_data|
          expect(section_data).to have_key(:subsections)
          expect(section_data[:subsections]).to be_a(Hash)
          expect(section_data[:subsections]).not_to be_empty
        end
      end

      it 'contains cells for each subsection' do
        nested_definitions.each do |_section_key, section_data|
          section_data[:subsections].each do |_subsection_key, subsection_data|
            expect(subsection_data).to have_key(:cells)
            expect(subsection_data[:cells]).to be_a(Hash)
            expect(subsection_data[:cells]).not_to be_empty
          end
        end
      end

      it 'contains properly structured cell data' do
        nested_definitions.each do |_section_key, section_data|
          section_data[:subsections].each do |_subsection_key, subsection_data|
            subsection_data[:cells].each do |cell_key, cell_data|
              expect(cell_key).to be_a(Symbol)
              expect(cell_data).to have_key(:calculation)
              expect(cell_data).to have_key(:label)
              expect(cell_data[:label]).to be_a(String)
            end
          end
        end
      end
    end
  end

  describe 'derived methods' do
    describe '#section_labels' do
      let(:section_labels) { report.send(:section_labels) }

      it 'returns labels for all sections' do
        expect(section_labels.keys).to contain_exactly('A', 'D', 'E', 'F', 'G', 'H')
      end

      it 'returns correct section labels' do
        expect(section_labels['A']).to eq('A. Core Services')
        expect(section_labels['D']).to eq('D. Prevention Demographics')
        expect(section_labels['E']).to eq('E. Homeless/rehousing Demographics')
        expect(section_labels['F']).to eq('F. Outcomes')
        expect(section_labels['G']).to include('G. Demographics of Rehousing Outcomes')
        expect(section_labels['H']).to include('H. Demographics of Rehousing Outcomes')
      end
    end

    describe '#subsection_labels' do
      let(:subsection_labels) { report.send(:subsection_labels) }

      it 'returns labels for all subsections' do
        expected_subsections = ['A1', 'A2', 'A3', 'A4', 'A_Total', 'D1', 'D2', 'D3', 'D4', 'E1', 'E2', 'E3', 'E4', 'F1', 'F2', 'G1', 'G2', 'G3', 'H1', 'H2', 'H3']
        expect(subsection_labels.keys).to contain_exactly(*expected_subsections)
      end

      it 'returns properly formatted subsection labels' do
        expect(subsection_labels['A1']).to eq({ text: '1. Street Outreach/Colaboration' })
        expect(subsection_labels['D1']).to eq({ text: '1. Age and Gender' })
        expect(subsection_labels['E1']).to eq({ text: '1. Age and Gender' })
        expect(subsection_labels['F1']).to eq({ text: '1. Prevention / Diversion/ Problem Solving Outcomes (Follow up)' })
        expect(subsection_labels['F2']).to eq({ text: '2. Rehousing Outcomes' })
        expect(subsection_labels['H1']).to eq({ text: '1. Age and Gender' })
      end
    end

    describe '#calculators' do
      let(:calculators) { report.send(:calculators) }

      it 'returns calculation objects for all cells' do
        expect(calculators).to be_a(Hash)
        expect(calculators.keys.count).to eq(120)
      end

      it 'includes expected cell keys' do
        expect(calculators.keys).to include(:A1a, :A1b, :D1a, :E1a, :F1a, :F2a, :G1a, :H1a)
      end

      it 'preserves the correct order' do
        keys = calculators.keys
        expect(keys.first(5)).to eq([:A1a, :A1b, :A2a, :A2b, :A3a])
        expect(keys).to include(:F1a, :F1b, :F1c, :F1d, :F1e) # F1 cells
        expect(keys).to include(:E1a, :E2a, :E3a, :E4a) # E section cells
        expect(keys).to include(:H1a, :H2a, :H3a) # H section cells
      end
    end

    describe '#cell_labels' do
      let(:cell_labels) { report.send(:cell_labels) }

      it 'returns labels for all cells' do
        expect(cell_labels).to be_a(Hash)
        expect(cell_labels.keys.count).to eq(120)
      end

      it 'includes expected cell keys' do
        expect(cell_labels.keys).to include(:A1a, :A1b, :D1a, :E1a, :F1a, :F2a, :G1a, :H1a)
      end

      it 'contains meaningful labels' do
        expect(cell_labels[:A1a]).to eq('Unduplicated number of outreach contacts with YYA experiencing homelessness')
        expect(cell_labels[:D1a]).to eq('Number of YYA served who were Under 18')
        expect(cell_labels[:F1a]).to eq('Number of YYA served in prevention who remained housed during reporting period')
        expect(cell_labels[:E1a]).to eq('Number of YYA served who were Under 18')
      end

      it 'preserves the correct order' do
        keys = cell_labels.keys
        expect(keys.first(5)).to eq([:A1a, :A1b, :A2a, :A2b, :A3a])
        expect(keys).to include(:F1a, :F1b, :F1c, :F1d, :F1e) # F1 cells
      end
    end

    describe '#labels' do
      let(:labels) { report.labels }

      it 'returns the same keys as calculators' do
        expect(labels).to eq(report.send(:calculators).keys)
      end

      it 'preserves the correct order' do
        expect(labels.first(5)).to eq([:A1a, :A1b, :A2a, :A2b, :A3a])
      end
    end
  end

  describe 'method consistency' do
    it 'ensures all derived methods return the same keys in the same order' do
      calculators_keys = report.send(:calculators).keys
      cell_labels_keys = report.send(:cell_labels).keys
      labels_keys = report.labels

      expect(calculators_keys).to eq(cell_labels_keys)
      expect(calculators_keys).to eq(labels_keys)
      expect(cell_labels_keys).to eq(labels_keys)
    end

    it 'maintains consistent cell count across all methods' do
      expected_count = 120

      expect(report.send(:calculators).keys.count).to eq(expected_count)
      expect(report.send(:cell_labels).keys.count).to eq(expected_count)
      expect(report.labels.count).to eq(expected_count)
    end
  end

  describe 'public interface methods' do
    describe '#section_label' do
      it 'returns correct section labels' do
        expect(report.section_label('A')).to eq('A. Core Services')
        expect(report.section_label('D')).to eq('D. Prevention Demographics')
        expect(report.section_label('E')).to eq('E. Homeless/rehousing Demographics')
        expect(report.section_label('F')).to eq('F. Outcomes')
      end

      it 'returns nil for non-existent sections' do
        expect(report.section_label('Z')).to be_nil
      end
    end

    describe '#subsection_label' do
      it 'returns correct subsection labels' do
        expect(report.subsection_label('A1')).to eq({ text: '1. Street Outreach/Colaboration' })
        expect(report.subsection_label('D1')).to eq({ text: '1. Age and Gender' })
        expect(report.subsection_label('F1')).to eq({ text: '1. Prevention / Diversion/ Problem Solving Outcomes (Follow up)' })
      end

      it 'returns default for non-existent subsections' do
        expect(report.subsection_label('Z1')).to eq({ text: '' })
      end
    end

    describe '#cell_label' do
      it 'returns correct cell labels' do
        expect(report.cell_label(:A1a)).to eq('Unduplicated number of outreach contacts with YYA experiencing homelessness')
        expect(report.cell_label(:F1a)).to eq('Number of YYA served in prevention who remained housed during reporting period')
      end

      it 'returns nil for non-existent cells' do
        expect(report.cell_label(:NonExistent)).to be_nil
      end
    end
  end

  describe 'specific section content validation' do
    describe 'Section A (Core Services)' do
      let(:section_a) { report.send(:nested_cell_definitions)['A'] }

      it 'contains all expected subsections' do
        expect(section_a[:subsections].keys).to contain_exactly('A1', 'A2', 'A3', 'A4', 'A_Total')
      end

      it 'contains expected cells in A1 subsection' do
        expect(section_a[:subsections]['A1'][:cells].keys).to contain_exactly(:A1a, :A1b)
      end

      it 'contains expected cells in A_Total subsection' do
        expect(section_a[:subsections]['A_Total'][:cells].keys).to contain_exactly(:TotalYYAServedPrevention, :TotalYYAServedHomeless)
      end
    end

    describe 'Section D (Demographics)' do
      let(:section_d) { report.send(:nested_cell_definitions)['D'] }

      it 'contains all expected subsections' do
        expect(section_d[:subsections].keys).to contain_exactly('D1', 'D2', 'D3', 'D4')
      end

      it 'contains expected number of cells in each subsection' do
        expect(section_d[:subsections]['D1'][:cells].keys.count).to eq(7) # D1a-D1g
        expect(section_d[:subsections]['D2'][:cells].keys.count).to eq(11) # D2a-D2k
        expect(section_d[:subsections]['D3'][:cells].keys.count).to eq(4) # D3a-D3d
        expect(section_d[:subsections]['D4'][:cells].keys.count).to eq(12) # D4a-D4l
      end
    end

    describe 'Section F (Outcomes)' do
      let(:section_f) { report.send(:nested_cell_definitions)['F'] }

      it 'contains expected subsections' do
        expect(section_f[:subsections].keys).to contain_exactly('F1', 'F2')
      end

      it 'contains expected cells in F1 subsection' do
        expect(section_f[:subsections]['F1'][:cells].keys).to contain_exactly(:F1a, :F1b, :F1c, :F1d, :F1e)
      end

      it 'contains expected cells in F2 subsection' do
        expect(section_f[:subsections]['F2'][:cells].keys).to contain_exactly(:F2a, :F2b, :F2c, :F2d, :F2e)
      end
    end

    describe 'Section E (Homeless/rehousing Demographics)' do
      let(:section_e) { report.send(:nested_cell_definitions)['E'] }

      it 'contains all expected subsections' do
        expect(section_e[:subsections].keys).to contain_exactly('E1', 'E2', 'E3', 'E4')
      end

      it 'contains expected number of cells in each subsection' do
        expect(section_e[:subsections]['E1'][:cells].keys.count).to eq(7) # E1a-E1g
        expect(section_e[:subsections]['E2'][:cells].keys.count).to eq(11) # E2a-E2k
        expect(section_e[:subsections]['E3'][:cells].keys.count).to eq(4) # E3a-E3d
        expect(section_e[:subsections]['E4'][:cells].keys.count).to eq(12) # E4a-E4l
      end
    end

    describe 'Section G (Demographics of Rehousing Outcomes)' do
      let(:section_g) { report.send(:nested_cell_definitions)['G'] }

      it 'contains all expected subsections' do
        expect(section_g[:subsections].keys).to contain_exactly('G1', 'G2', 'G3')
      end

      it 'contains expected number of cells in each subsection' do
        expect(section_g[:subsections]['G1'][:cells].keys.count).to eq(7) # G1a-G1g
        expect(section_g[:subsections]['G2'][:cells].keys.count).to eq(8) # G2a-G2h
        expect(section_g[:subsections]['G3'][:cells].keys.count).to eq(1) # G3a
      end
    end

    describe 'Section H (Demographics of Rehousing Outcomes)' do
      let(:section_h) { report.send(:nested_cell_definitions)['H'] }

      it 'contains all expected subsections' do
        expect(section_h[:subsections].keys).to contain_exactly('H1', 'H2', 'H3')
      end

      it 'contains expected number of cells in each subsection' do
        expect(section_h[:subsections]['H1'][:cells].keys.count).to eq(7) # H1a-H1g
        expect(section_h[:subsections]['H2'][:cells].keys.count).to eq(8) # H2a-H2h
        expect(section_h[:subsections]['H3'][:cells].keys.count).to eq(1) # H3a
      end
    end
  end

  describe 'memoization' do
    it 'memoizes nested_cell_definitions' do
      first_call = report.send(:nested_cell_definitions)
      second_call = report.send(:nested_cell_definitions)
      expect(first_call).to be(second_call) # Same object reference
    end

    it 'memoizes calculators' do
      first_call = report.send(:calculators)
      second_call = report.send(:calculators)
      expect(first_call).to be(second_call)
    end

    it 'memoizes cell_labels' do
      first_call = report.send(:cell_labels)
      second_call = report.send(:cell_labels)
      expect(first_call).to be(second_call)
    end

    it 'memoizes section_labels' do
      first_call = report.send(:section_labels)
      second_call = report.send(:section_labels)
      expect(first_call).to be(second_call)
    end

    it 'memoizes subsection_labels' do
      first_call = report.send(:subsection_labels)
      second_call = report.send(:subsection_labels)
      expect(first_call).to be(second_call)
    end
  end
end
