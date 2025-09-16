# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppResourceMonitor::CollectStatsJob, type: :job do
  describe '#perform' do
    let!(:s3_credential) { create(:grda_remote_s3, slug: 'app_stats', path: 'stats_path', active: true) }
    let(:report_double) { instance_double(AppResourceMonitor::Report) }
    let(:s3_client_double) { instance_double(AwsS3) }
    let(:temp_directory) { Dir.mktmpdir }
    let(:job) { described_class.new }

    before do
      allow(AppResourceMonitor::Report).to receive(:new).and_return(report_double)
      allow(report_double).to receive(:export_to_csv).and_yield(temp_directory)
      allow(s3_credential).to receive(:s3).and_return(s3_client_double)
      allow(s3_client_double).to receive(:upload_directory)
      allow(job).to receive(:active_config).and_return(s3_credential)
      allow(job).to receive(:active_config?).and_return(true)
      allow(job).to receive(:instrument_as_maintenance_task).and_yield(double(complete!: true))
    end

    after do
      FileUtils.remove_entry(temp_directory) if Dir.exist?(temp_directory)
    end

    it 'exports stats to csv and uploads to s3' do
      job.perform

      expect(report_double).to have_received(:export_to_csv)
      expect(s3_client_double).to have_received(:upload_directory).with(
        directory_name: temp_directory,
        prefix: "stats_path/#{ENV.fetch('CLIENT', nil)}-#{Rails.env}",
      )
    end
  end
end
