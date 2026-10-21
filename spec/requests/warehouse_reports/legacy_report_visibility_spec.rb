###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Legacy warehouse report visibility', type: :request do
  # Minimum parameters each report's index and show views need to render.
  report_parameters = {
    'chronic' => { filter: {} },
    'hud_chronics' => { filter: {} },
    'disabilities' => { filter: { start: '2024-01-01', end: '2024-12-31', sub_population: 'clients', disabilities: ['6'], project_types: ['1'] } },
    'active_veterans' => { range: {} },
  }
  # Parameters for a queued run whose rendered row shows `label`, so specs can tell runs apart.
  queued_run_parameters = {
    'chronic' => ->(label) { { filter: { label: label } } },
    'hud_chronics' => ->(label) { { filter: { label: label } } },
    'disabilities' => ->(label) { report_parameters['disabilities'].deep_merge(filter: { start: label }) },
    'active_veterans' => ->(label) { { range: { label: label } } },
  }

  {
    'chronic' => [GrdaWarehouse::WarehouseReports::ChronicReport, :warehouse_reports_chronic_path, :warehouse_reports_chronic_index_path, :running_warehouse_reports_chronic_index_path, WarehouseReports::RunChronicJob],
    'hud_chronics' => [GrdaWarehouse::WarehouseReports::HudChronicReport, :warehouse_reports_hud_chronic_path, :warehouse_reports_hud_chronics_path, :running_warehouse_reports_hud_chronics_path, WarehouseReports::RunHudChronicJob],
    'disabilities' => [GrdaWarehouse::WarehouseReports::EnrolledDisabledReport, :warehouse_reports_disability_path, :warehouse_reports_disabilities_path, :running_warehouse_reports_disabilities_path, WarehouseReports::RunEnrolledDisabledJob],
    'active_veterans' => [GrdaWarehouse::WarehouseReports::ActiveVeteransReport, :warehouse_reports_active_veteran_path, :warehouse_reports_active_veterans_path, :running_warehouse_reports_active_veterans_path, WarehouseReports::RunActiveVeteransJob],
  }.each do |slug, (klass, member_helper, index_helper, running_helper, job_class)|
    describe slug do
      let(:report_class) { klass }
      let(:report_definition_url) { "warehouse_reports/#{slug}" }
      let(:report_path) { ->(report) { public_send(member_helper, report) } }

      it_behaves_like 'report member actions limited to visible reports' do
        let(:report_attributes) { { parameters: report_parameters.fetch(slug) } }
      end

      describe 'index' do
        include_context 'report visibility users'

        let(:report_attributes) { { parameters: report_parameters.fetch(slug) } }

        before { sign_in(own_reports_user) }

        it "lists the user's own report and not one run by another user" do
          get public_send(index_helper)

          expect(response.body).to include(public_send(member_helper, own_report))
          expect(response.body).not_to include(public_send(member_helper, others_report))
        end

        it "lists the user's own report and not one run by another user when polling running reports" do
          get public_send(running_helper, format: :js), xhr: true

          expect(response.body).to include(public_send(member_helper, own_report))
          expect(response.body).not_to include(public_send(member_helper, others_report))
        end

        context 'with a queued run from each user' do
          before do
            enqueue_report_job(job_class.new(queued_run_parameters.fetch(slug).call('own-queued-run').merge(current_user_id: own_reports_user.id).with_indifferent_access))
            enqueue_report_job(job_class.new(queued_run_parameters.fetch(slug).call('others-queued-run').merge(current_user_id: all_reports_user.id).with_indifferent_access))
          end

          it "lists only the user's own queued run" do
            get public_send(index_helper)

            expect(queued_row_count).to eq(1)
            expect(response.body).to include('own-queued-run')
            expect(response.body).not_to include('others-queued-run')
          end

          it "lists only the user's own queued run when polling running reports" do
            get public_send(running_helper, format: :js), xhr: true

            expect(queued_row_count).to eq(1)
            expect(response.body).to include('own-queued-run')
            expect(response.body).not_to include('others-queued-run')
          end

          it 'lists every queued run for a user who can view all reports' do
            sign_in(all_reports_user)
            get public_send(index_helper)

            expect(queued_row_count).to eq(2)
            expect(response.body).to include('own-queued-run', 'others-queued-run')
          end

          if slug == 'hud_chronics'
            # Reporting::RunHudChronicJob also matches the handler search but carries client ids, not report parameters.
            it 'skips chronic recalculation jobs' do
              enqueue_report_job(Reporting::RunHudChronicJob.new([1], Date.current.to_s))
              sign_in(all_reports_user)
              get public_send(index_helper)

              expect(queued_row_count).to eq(2)
            end
          end
        end
      end
    end
  end

  # The test environment uses the :test adapter, so write the Delayed::Job rows the controllers read.
  def enqueue_report_job(job)
    Delayed::Job.enqueue(ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(job.serialize))
  end

  def queued_row_count
    response.body.scan('jIncompleteReport').size
  end
end
