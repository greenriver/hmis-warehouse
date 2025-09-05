# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'ac_hmis rake tasks', type: :task do
  let(:task_name) { 'ac_hmis:import_housing_assessments' }

  before do
    Rake::Task.clear
    Rake.application = Rake::Application.new
    load Rails.root.join('drivers/hmis_external_apis/lib/tasks/ac_hmis.rake')
    Rake::Task.define_task(:environment)

    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow(HmisExternalApis::AcHmis::Mci).to receive(:enabled?).and_return(true)
  end

  def run_task(bucket_name, s3_key, project_id)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke(bucket_name, s3_key, project_id)
  end

  it 'downloads from s3 to a tempfile and invokes the importer with the temp path' do
    bucket_name = 'my-bucket'
    s3_key = 'path/to/wait_list.xlsx'
    project_id = '123'

    s3_double = instance_double('AwsS3')
    allow(AwsS3).to receive(:new).with(bucket_name: bucket_name).and_return(s3_double)

    downloaded_path = nil
    allow(s3_double).to receive(:fetch) do |file_name:, target_path:, **_|
      expect(file_name).to eq(s3_key)
      downloaded_path = target_path
    end

    importer = HmisExternalApis::AcHmis::Importers::HousingAssessmentImporter
    allow(importer).to receive(:call)

    run_task(bucket_name, s3_key, project_id)

    expect(importer).to have_received(:call) do |path, ce_project_id:, dry_run:|
      expect(path).to eq(downloaded_path)
      expect(ce_project_id).to eq(123)
      expect(dry_run).to eq(false)
    end

    # Tempfile should be cleaned up after the task completes
    expect(File.exist?(downloaded_path)).to be(false)
  end
end
