require 'rails_helper'
# You'll need `docker-compose up -d sftp` before this will work
RSpec.describe MedicaidHmisInterchange::FileExchangeJob, type: :model do
  let!(:sftp_credentials) { create(:mhx_sftp_credentials) }
  let!(:job) { described_class.new }

  before :each do
    cleanup_sftp_directory
    job.send(:using_sftp) do |sftp|
      # NOTES for ls of SFTP
      # sftp.dir.foreach("/") do |entry|
      #   puts entry.longname
      # end
      sftp.mkdir!("#{sftp_credentials[:path]}/to_ehs")
      sftp.mkdir!("#{sftp_credentials[:path]}/from_ehs")
    end
  end

  # after :all do
  #   cleanup_sftp_directory
  # end

  it 'checks empty file list' do
    files = job.send(:fetch_file_list, 'to_ehs')

    expect(files).to be_empty
  end

  it 'creates a trigger file' do
    job.send(:touch_trigger_file)
    files = job.send(:fetch_file_list, 'to_ehs')

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

    it 'submits for the first time' do
      job.perform

      files = job.send(:fetch_file_list, 'to_ehs')

      expect(files.count).to eq(2) # The zip file, and the trigger file
    end

    it "doesn't submit if pending" do
      job.perform
      job.perform

      files = job.send(:fetch_file_list, 'to_ehs')

      expect(files.count).to eq(2) # The zip file, and the trigger file
    end

    it 'continues after the last submission is processed' do
      job.perform

      most_recent_upload = MedicaidHmisInterchange::Health::Submission.last
      FileUtils.touch File.join('tmp/sftp_spec/from_ehs', most_recent_upload.response_filename)

      job.perform

      files = job.send(:fetch_file_list, 'to_ehs')
      expect(files.count).to eq(3) # processed + response and new submission
    end
  end

  def cleanup_sftp_directory
    FileUtils.rm_rf Dir.glob('tmp/sftp_spec/*')
  end
end
