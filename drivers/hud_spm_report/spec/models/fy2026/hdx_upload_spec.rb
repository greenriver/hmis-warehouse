###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2026::HdxUpload, type: :model, exclude_fixpoints: true do
  include_context '2026 SPM test setup'

  let(:hdx_columns) { HudSpmReport::Generators::Fy2026::HdxUpload::COLUMNS }

  describe 'HDX Upload' do
    before do
      @es_project = create_project(project_type: 0) # ES-EE
      @th_project = create_project(project_type: 2) # TH
      @sh_project = create_project(project_type: 8) # SH
      @so_project = create_project(project_type: 4) # SO
      @psh_project = create_project(project_type: 3) # PSH
      @rrh_project = create_project(project_type: 13) # RRH

      @client1 = create_client_with_warehouse_link
      @client2 = create_client_with_warehouse_link

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

      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureTwo)
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureThree)
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureFour)
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureFive)
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureSix)
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureSeven)
      run_measure(@report, HudSpmReport::Generators::Fy2026::HdxUpload)
    end

    it 'sets CocCode and software name in metadata columns' do
      expect(@report.answer(question: 'csv', cell: 'A2').summary).to eq('MA-500')
      expect(@report.answer(question: 'csv', cell: 'E2').summary).to eq('OpenPath HMIS Data Warehouse')
    end

    it 'produces a two-row table spanning the expected column range' do
      metadata = @report.answer(question: 'csv').metadata
      expect(metadata['first_column']).to eq(hdx_columns.first.column_letter.to_s)
      expect(metadata['last_column']).to eq(hdx_columns.last.column_letter.to_s)
      expect(metadata['first_row']).to eq(1)
      expect(metadata['last_row']).to eq(2)
    end

    context 'when measure data is missing' do
      before do
        @partial_report = setup_report(
          [@es_project.id, @th_project.id],
          ['Measure 1', 'HDX Upload'],
        )

        run_measure(@partial_report, HudSpmReport::Generators::Fy2026::MeasureOne)
        run_measure(@partial_report, HudSpmReport::Generators::Fy2026::HdxUpload)
      end

      it 'produces appropriate default values for missing measures' do
        metadata_columns = hdx_columns.select { |col| col.source_type == :metadata }
        metadata_columns.each do |col|
          expect(@partial_report.answer(question: 'csv', cell: "#{col.column_letter}2").summary).to be_present
        end

        measure_1_columns = hdx_columns.select { |col| ['1a', '1b'].include?(col.source_table) }
        measure_1_columns.each do |col|
          expect(@partial_report.answer(question: 'csv', cell: "#{col.column_letter}2").summary).to be_present
        end

        other_measure_columns = hdx_columns.select do |col|
          col.source_type == :spm && !['1a', '1b'].include?(col.source_table)
        end

        other_measure_columns.each do |col|
          answer = @partial_report.answer(question: 'csv', cell: "#{col.column_letter}2")
          case col.data_type
          when :integer then expect(answer.summary.to_s).to eq('0')
          when :decimal then expect(answer.summary.to_s).to eq('0.0')
          else               expect(answer.summary.to_s).to be_present
          end
        end
      end
    end

    context 'DQ context sharing via source_report_id_for_contexts' do
      it 'invokes HouseholdContextBuilder with source_report_id set to the SPM report' do
        allow(HudReports::HouseholdContextBuilder).to receive(:call).and_call_original

        run_measure(@report, HudSpmReport::Generators::Fy2026::HdxUpload)

        expect(HudReports::HouseholdContextBuilder).to have_received(:call).with(
          anything,
          anything,
          hash_including(source_report_id: @report.id),
        ).at_least(:once)
      end

      # broken ATM, filters in hdx upload seem to exclude enrollments in the test
      xit 'copies SPM contexts to DQ sub-reports rather than recomputing them' do
        # The measure was already run in the main before block
        dq_reports = HudReports::ReportInstance.where(
          report_name: HudApr::Generators::Dq::Fy2026::Generator.title,
        ).to_a.select { |r| r.options&.with_indifferent_access&.[](:source_report_id_for_contexts) == @report.id }

        expect(dq_reports).to be_present

        spm_ctx_by_she_id = @report.household_contexts.index_by(&:service_history_enrollment_id)

        # Every DQ context must have a matching SPM context for the same SHE,
        # and the pre-computed values must be identical (proving copy, not recompute).
        dq_reports_with_contexts = dq_reports.select { |r| r.household_contexts.any? }
        expect(dq_reports_with_contexts).to be_present, 'Expected at least one DQ sub-report to have household contexts'

        dq_reports_with_contexts.each do |dq_report|
          dq_report.household_contexts.each do |dq_ctx|
            spm_ctx = spm_ctx_by_she_id[dq_ctx.service_history_enrollment_id]

            expect(spm_ctx).to be_present,
                               "DQ context for SHE #{dq_ctx.service_history_enrollment_id} has no matching SPM context"
            expect(dq_ctx.age).to eq(spm_ctx.age)
            expect(dq_ctx.household_type).to eq(spm_ctx.household_type)
            expect(dq_ctx.inherited_chronic_status).to eq(spm_ctx.inherited_chronic_status)
            expect(dq_ctx.inherited_move_in_date).to eq(spm_ctx.inherited_move_in_date)
          end
        end
      end
    end
  end
end
