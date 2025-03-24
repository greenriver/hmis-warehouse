# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2024::HdxUpload, type: :model do
  include_context 'SPM test setup'

  # We'll test against the CSV column definitions
  let(:hdx_columns) { HudSpmReport::Generators::Fy2024::HdxUpload::COLUMNS }

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
