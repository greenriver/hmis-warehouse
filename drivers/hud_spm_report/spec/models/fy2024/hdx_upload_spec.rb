# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2024::HdxUpload, type: :model do
  include_context 'SPM test setup'

  # We'll test against the CSV column definitions
  let(:hdx_columns) do
    # HudSpmReport::Generators::Fy2024::HdxUpload::COLUMNS changed structure. This is the old definition which is left
    # in the test for now to ensure we haven't made accidental changes the col defs
    {
      A: ['CocCode', :metadata],
      B: ['ReportDateTime', :metadata],
      C: ['ReportStartDate', :metadata],
      D: ['ReportEndDate', :metadata],
      E: ['SoftwareName', :metadata],
      F: ['SourceContactFirst', :metadata],
      G: ['SourceContactLast', :metadata],
      H: ['SourceContactEmail', :metadata],

      I: ['ESSHUniverse_1A', :spm, '1a', :B1],
      J: ['ESSHAvgTime_1A', :spm, '1a', :D1],
      K: ['ESSHMedianTime_1A', :spm, '1a', :G1],
      L: ['ESSHTHUniverse_1A', :spm, '1a', :B2],
      M: ['ESSHTHAvgTime_1A', :spm, '1a', :D2],
      N: ['ESSHTHMedianTime_1A', :spm, '1a', :G2],

      O: ['ESSHUniverse_1B', :spm, '1b', :B1],
      P: ['ESSHAvgTime_1B', :spm, '1b', :D1],
      Q: ['ESSHMedianTime_1B', :spm, '1b', :G1],
      R: ['ESSHTHUniverse_1B', :spm, '1b', :B2],
      S: ['ESSHTHAvgTime_1B', :spm, '1b', :D2],
      T: ['ESSHTHMedianTime_1B', :spm, '1b', :G2],

      U: ['SOExitPH_2', :spm, '2a and 2b', :B2],
      V: ['SOReturn0to180_2', :spm, '2a and 2b', :C2],
      W: ['SOReturn181to365_2', :spm, '2a and 2b', :E2],
      X: ['SOReturn366to730_2', :spm, '2a and 2b', :G2],
      Y: ['ESExitPH_2', :spm, '2a and 2b', :B3],
      Z: ['ESReturn0to180_2', :spm, '2a and 2b', :C3],
      AA: ['ESReturn181to365_2', :spm, '2a and 2b', :E3],
      AB: ['ESReturn366to730_2', :spm, '2a and 2b', :G3],
      AC: ['THExitPH_2', :spm, '2a and 2b', :B4],
      AD: ['THReturn0to180_2', :spm, '2a and 2b', :C4],
      AE: ['THReturn181to365_2', :spm, '2a and 2b', :E4],
      AF: ['THReturn366to730_2', :spm, '2a and 2b', :G4],
      AG: ['SHExitPH_2', :spm, '2a and 2b', :B5],
      AH: ['SHReturn0to180_2', :spm, '2a and 2b', :C5],
      AI: ['SHReturn181to365_2', :spm, '2a and 2b', :E5],
      AJ: ['SHReturn366to730_2', :spm, '2a and 2b', :G5],
      AK: ['PHExitPH_2', :spm, '2a and 2b', :B6],
      AL: ['PHReturn0to180_2', :spm, '2a and 2b', :C6],
      AM: ['PHReturn181to365_2', :spm, '2a and 2b', :E6],
      AN: ['PHReturn366to730_2', :spm, '2a and 2b', :G6],

      AO: ['TotalAnnual_3', :spm, '3.2', :C2],
      AP: ['ESAnnual_3', :spm, '3.2', :C3],
      AQ: ['SHAnnual_3', :spm, '3.2', :C4],
      AR: ['THAnnual_3', :spm, '3.2', :C5],

      AS: ['AdultStayers_4', :spm, '4.1', :C2],
      AT: ['IncreaseEarned4_1', :spm, '4.1', :C3],

      AU: ['IncreaseOther4_2', :spm, '4.2', :C3],

      AV: ['IncreaseTotal4_3', :spm, '4.3', :C3],

      AW: ['AdultLeavers_4', :spm, '4.4', :C2],
      AX: ['IncreaseEarned4_4', :spm, '4.4', :C3],

      AY: ['IncreaseOther4_5', :spm, '4.5', :C3],

      AZ: ['IncreaseTotal4_6', :spm, '4.6', :C3],

      BA: ['EnterESSHTH5_1', :spm, '5.1', :C2],
      BB: ['ESSHTHWithPriorSvc5_1', :spm, '5.1', :C3],

      BC: ['EnterESSHTHPH5_2', :spm, '5.2', :C2],
      BD: ['ESSHTHPHWithPriorSvc5_2', :spm, '5.2', :C3],

      BE: ['THExitPH_6', :spm, '6a.1 and 6b.1', :B4],
      BF: ['THReturn0to180_6', :spm, '6a.1 and 6b.1', :C4],
      BG: ['THReturn181to365_6', :spm, '6a.1 and 6b.1', :E4],
      BH: ['THReturn366to730_6', :spm, '6a.1 and 6b.1', :G4],
      BI: ['SHExitPH_6', :spm, '6a.1 and 6b.1', :B5],
      BJ: ['SHReturn0to180_6', :spm, '6a.1 and 6b.1', :C5],
      BK: ['SHReturn181to365_6', :spm, '6a.1 and 6b.1', :E5],
      BL: ['SHReturn366to730_6', :spm, '6a.1 and 6b.1', :G5],
      BM: ['PHExitPH_6', :spm, '6a.1 and 6b.1', :B6],
      BN: ['PHReturn0to180_6', :spm, '6a.1 and 6b.1', :C6],
      BO: ['PHReturn181to365_6', :spm, '6a.1 and 6b.1', :E6],
      BP: ['PHReturn366to730_6', :spm, '6a.1 and 6b.1', :G6],

      BQ: ['SHTHRRHCat3Leavers_6', :spm, '6c.1', :C2],
      BR: ['SHTHRRHCat3ExitPH_6', :spm, '6c.1', :C3],

      BS: ['PSHCat3Clients_6', :spm, '6c.2', :C2],
      BT: ['PSHCat3StayOrExitPH_6', :spm, '6c.2', :C3],

      BU: ['SOExit_7', :spm, '7a.1', :C2],
      BV: ['SOExitTempInst_7', :spm, '7a.1', :C3],
      BW: ['SOExitPH_7', :spm, '7a.1', :C4],

      BX: ['ESSHTHRRHExit_7', :spm, '7b.1', :C2],
      BY: ['ESSHTHRRHToPH_7', :spm, '7b.1', :C3],

      BZ: ['PHClients_7', :spm, '7b.2', :C2],
      CA: ['PHClientsStayOrExitPH_7', :spm, '7b.2', :C3],

      CB: ['ESSH_UndupHMIS_DQ', :essh, 'Q1', :B2],
      CC: ['TH_UndupHMIS_DQ', :th, 'Q1', :B2],
      CD: ['PSHOPH_UndupHMIS_DQ', :pshoph, 'Q1', :B2],
      CE: ['RRH_UndupHMIS_DQ', :rrh, 'Q1', :B2],
      CF: ['StOutreach_UndupHMIS_DQ', :so, 'Q1', :B2],
      CG: ['ESSH_LeaversHMIS_DQ', :essh, 'Q1', :B6],
      CH: ['TH_LeaversHMIS_DQ', :th, 'Q1', :B6],
      CI: ['PSHOPH_LeaversHMIS_DQ', :pshoph, 'Q1', :B6],
      CJ: ['RRH_LeaversHMIS_DQ', :rrh, 'Q1', :B6],
      CK: ['StOutreach_LeaversHMIS_DQ', :so, 'Q1', :B6],

      CL: ['ESSH_DkRMHMIS_DQ', :essh, 'Q4', :E2],
      CM: ['TH_DkRMHMIS_DQ', :th, 'Q4', :E2],
      CN: ['PSHOPH_DkRMHMIS_DQ', :pshoph, 'Q4', :E2],
      CO: ['RRH_DkRMHMIS_DQ', :rrh, 'Q4', :E2],
      CP: ['StOutreach_DkRMHMIS_DQ', :so, 'Q4', :E2],

    }.freeze
  end

  describe 'HDX Upload' do
    before do
      # Setup projects of different types
      @es_project = create_project(project_type: 0) # ES-EE
      @th_project = create_project(project_type: 2) # TH
      @sh_project = create_project(project_type: 8) # SH
      @so_project = create_project(project_type: 4) # SO
      @psh_project = create_project(project_type: 3) # PSH
      @rrh_project = create_project(project_type: 13) # RRH

      # Create a few clients
      @client1 = create_client_with_warehouse_link
      @client2 = create_client_with_warehouse_link

      # Create enrollments with some reasonable data
      create_enrollment(
        client: @client1,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: '2022-10-15'.to_date,
      )

      create_enrollment(
        client: @client1,
        project: @th_project,
        entry_date: '2023-02-01'.to_date,
        exit_date: '2023-04-15'.to_date,
      )

      create_enrollment(
        client: @client2,
        project: @sh_project,
        entry_date: '2022-12-01'.to_date,
        exit_date: '2023-02-15'.to_date,
      )

      # Setup and run the report with all measures
      @report = setup_report(
        [@es_project.id, @th_project.id, @sh_project.id, @so_project.id, @psh_project.id, @rrh_project.id],
        [
          'Measure 1',
          'Measure 2',
          'Measure 3',
          'Measure 4',
          'Measure 5',
          'Measure 6',
          'Measure 7',
          'HDX Upload',
        ],
      )

      # Run all the measures first to populate data
      run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
      run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureTwo)
      run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureThree)
      run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureFour)
      run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureFive)
      run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureSix)
      run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureSeven)

      # Finally run the HDX Upload to generate the CSV
      run_measure(@report, HudSpmReport::Generators::Fy2024::HdxUpload)
    end

    # Test that all headers are properly set in the first row
    it 'sets all column headers correctly' do
      hdx_columns.each do |column, (label, _section, *_args)|
        answer = @report.answer(question: 'csv', cell: "#{column}1")
        expect(answer.summary).to eq(label)
      end
    end

    # Test metadata fields
    it 'properly populates metadata fields' do
      metadata_columns = hdx_columns.select { |_col, (_, section, *_)| section == :metadata }

      metadata_columns.each do |column, (_label, _section, *_)|
        answer = @report.answer(question: 'csv', cell: "#{column}2")
        expect(answer.summary).to be_present, "Expected value for metadata column #{column}"

        # Test specific metadata fields
        case column
        when :A
          # CocCode
          expect(answer.summary).to eq('MA-500')
        when :E
          # Software name
          expect(answer.summary).to eq('OpenPath HMIS Data Warehouse')
        end
      end
    end

    # Test that all SPM data fields are populated with non-null values
    it 'has non-null values for all SPM fields' do
      spm_columns = hdx_columns.select { |_col, (_, section, *_)| section == :spm }

      spm_columns.each do |column, (_label, _section, measure, cell)|
        source_value = @report.answer(question: measure, cell: cell)&.summary
        hdx_value = @report.answer(question: 'csv', cell: "#{column}2")&.summary

        # The value might be legitimately empty (e.g. if the measure wasn't calculated)
        # but it should never be nil
        expect(hdx_value).not_to be_nil, "Expected non-nil value for SPM column #{column} (measure #{measure}, cell #{cell})"

        # The HDX value should match what's in the source cell
        expect(hdx_value).to eq(source_value&.to_f || 0)
      end
    end

    # Test Data Quality Report fields are populated
    it 'populates Data Quality Report fields' do
      dq_sections = [:essh, :th, :pshoph, :rrh, :so]

      dq_sections.each do |section|
        columns = hdx_columns.select { |_col, (_, sec, *_)| sec == section }

        # Skip testing sections with no data, but there should be at least one
        # field populated if the section was processed successfully
        next if columns.empty?

        has_any_data = columns.any? do |column, (_label, _section, *_)|
          answer = @report.answer(question: 'csv', cell: "#{column}2")
          answer.summary.present?
        end

        expect(has_any_data).to be_truthy, "Expected at least one populated field for DQ section #{section}"
      end
    end

    # Test that the overall CSV generation is working properly
    it 'produces a valid CSV output with expected structure' do
      # Check that we have exactly two rows (header row and data row)
      row_1_cells = hdx_columns.map { |column, _| "#{column}1" }
      row_2_cells = hdx_columns.map { |column, _| "#{column}2" }

      # Verify all column headers are present
      row_1_cells.each do |cell_name|
        answer = @report.answer(question: 'csv', cell: cell_name)
        expect(answer).to be_present
      end

      # Verify all data cells are present
      row_2_cells.each do |cell_name|
        answer = @report.answer(question: 'csv', cell: cell_name)
        expect(answer).to be_present
      end

      # The table should have exactly the columns defined in COLUMNS
      metadata = @report.answer(question: 'csv').metadata
      expect(metadata['first_column']).to eq(hdx_columns.keys.first.to_s)
      expect(metadata['last_column']).to eq(hdx_columns.keys.last.to_s)
      expect(metadata['first_row']).to eq(1)
      expect(metadata['last_row']).to eq(2)
    end

    # Test that the HDX_Upload class can handle missing data gracefully
    context 'when measure data is missing' do
      before do
        # Create a fresh report with only some metrics run
        @partial_report = setup_report(
          [@es_project.id, @th_project.id],
          ['Measure 1', 'HDX Upload'], # Only run Measure 1
        )

        run_measure(@partial_report, HudSpmReport::Generators::Fy2024::MeasureOne)
        run_measure(@partial_report, HudSpmReport::Generators::Fy2024::HdxUpload)
      end

      it 'produces appropriate default values for missing measures' do
        # Metadata should still be present
        metadata_columns = hdx_columns.select { |_col, (_, section, *_)| section == :metadata }
        metadata_columns.each do |column, (_label, _section, *_args)|
          answer = @partial_report.answer(question: 'csv', cell: "#{column}2")
          expect(answer.summary).to be_present
        end

        # Measure 1 data should be present
        measure_1_columns = hdx_columns.select { |_col, (_, _section, measure, _cell)| ['1a', '1b'].include?(measure) }
        measure_1_columns.each do |column, (_label, _section, _measure, _cell)|
          answer = @partial_report.answer(question: 'csv', cell: "#{column}2")
          expect(answer.summary).to be_present
        end

        # Other measures should have appropriate default values based on data type
        other_measure_columns = hdx_columns.select do |_col, (_, section, measure, _cell, _data_type)|
          section == :spm && !['1a', '1b'].include?(measure)
        end

        other_measure_columns.each do |column, (_label, _section, _measure, _cell, data_type)|
          answer = @partial_report.answer(question: 'csv', cell: "#{column}2")

          case data_type
          when :integer
            expect(answer.summary.to_s).to eq('0')
          when :decimal
            expect(answer.summary.to_s).to eq('0.0')
          else
            expect(answer.summary.to_s).to be_present
          end
        end
      end
    end
  end
end
