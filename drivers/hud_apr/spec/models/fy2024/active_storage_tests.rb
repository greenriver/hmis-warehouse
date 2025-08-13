###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'active storage tests apr', shared_context: :metadata do
  describe 'APR ActiveStorage Migration Tests' do
    before(:all) do
      @generator = HudApr::Generators::Apr::Fy2024::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization S - RRH - 2']).pluck(:id)
      @filter = ::Filters::HudFilterBase.new(
        shared_filter_spec.merge(
          project_ids: Array.wrap(project_ids),
        ),
      )

      # Run the report once for all tests
      run(@generator, @filter)
      @report = ::HudReports::ReportInstance.last
      @service = HudReports::S3ArtifactService.new(@report)

      # Manually run the cleanup job to ensure it works
      expect do
        HudReports::StoreArtifactsAndCleanupJob.perform_now(@report.id)
      end.not_to raise_error
      @report.reload
    end

    after(:all) do
      # Clean up ActiveStorage attachments after all tests
      # Use delete_all to avoid callbacks that might cause issues
      ActiveStorage::Attachment.delete_all
      ActiveStorage::Blob.delete_all
    end

    it 'runs APR and stores artifacts to ActiveStorage' do
      expect(@report).to be_present
      expect(@report.artifacts_stored?).to be true
      expect(@report.universe_members_csv_shards).to be_attached
      expect(@report.report_clients_csv).to be_attached
      expect(@report.cell_details_csv).to be_attached
      expect(@report.report_summary_json).to be_attached
    end

    it 'verifies RDS data is cleaned up after artifact storage' do
      # First verify that the cleanup job has been triggered and run
      expect(@report.artifacts_stored_at).to be_present
      # binding.pry

      # Verify RDS data has been cleaned up
      report_cells = HudReports::ReportCell.where(report_instance_id: @report.id)
      # We are not cleaning up report cells, just the client data for each of them.
      expect(@report.report_cells).not_to be_empty

      expect(HudReports::UniverseMember.where(report_cell: report_cells)).to be_empty
      expect(HudApr::Fy2020::AprClient.where(report_instance_id: @report.id)).to be_empty
    end

    it 'verifies data can be retrieved from ActiveStorage' do
      questions = @report.report_cells.distinct.pluck(:question)
      expect(questions).not_to be_empty

      has_data = false
      questions.each do |question|
        csv_data = @service.retrieve_universe_members(question: question)
        has_data = true if csv_data.present?
      end

      # not all questions will have data, but we should have data for at least one
      expect(has_data).to be true
    end
  end
end
