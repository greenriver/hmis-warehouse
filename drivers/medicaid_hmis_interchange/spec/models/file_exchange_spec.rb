require 'rails_helper'

RSpec.describe MedicaidHmisInterchange::FileExchangeJob, type: :model do
  let!(:sftp_credentials) { create(:mhx_sftp_credentials) }
  let!(:job) { described_class.new }

  before :each do
    cleanup_sftp_directory
  end

  xit 'checks empty file list' do
    files = job.send(:fetch_file_list)

    expect(files).to be_empty
  end

  xit 'creates a trigger file' do
    job.send(:touch_trigger_file)
    files = job.send(:fetch_file_list)

    expect(files).to_not be_empty
  end

  describe 'with submittable data' do
    let!(:client) { create(:fixed_destination_client) }
    let!(:enrollment) { create :grda_warehouse_hud_enrollment, EntryDate: Date.current - 1.day, data_source_id: client.data_source_id }
    let!(:service_history_enrollment) do
      create(
        :grda_warehouse_service_history,
        :service_history_entry,
        client_id: client.id,
        first_date_in_program: Date.current - 1.day,
        enrollment: enrollment,
      )
    end

    before(:each) do
      client.build_external_health_id(identifier: 'TEST_ID')
      client.save!
    end

    xit 'submits for the first time' do
      job.perform

      files = job.send(:fetch_file_list)

      expect(files.count).to eq(2) # The zip file, and the trigger file
    end

    xit "doesn't submit if pending" do
      job.perform
      job.perform

      files = job.send(:fetch_file_list)

      expect(files.count).to eq(2) # The zip file, and the trigger file
    end

    xit 'continues after the last submission is processed' do
      job.perform

      most_recent_upload = MedicaidHmisInterchange::Health::Submission.last
      FileUtils.touch File.join('tmp', most_recent_upload.response_filename)

      job.perform

      files = job.send(:fetch_file_list)
      expect(files.count).to eq(4) # processed + response and new submission
    end
  end

  def cleanup_sftp_directory
    FileUtils.rm Dir.glob('tmp/*rdc_homeless*')
  end
end
