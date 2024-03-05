###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'HmisExternalApis::ConsumeExternalFormSubmissionsJob', type: :model do
  let!(:data_source) { create :hmis_data_source }

  let(:form_definition) do
    create(:hmis_external_form_definition)
  end

  let(:s3_client_double) { double('S3Client') }
  let(:s3_object_double) { double('S3Object', key: '1234', last_modified: 1.minute.ago) }
  let(:submission_document) do
    form_definition_id = ProtectedId::Encoder.encode(form_definition.id)
    { your_name: 'test 1', form_definition_id: form_definition_id }.to_json
  end

  before do
    allow_any_instance_of(HmisExternalApis::ConsumeExternalFormSubmissionsJob).to receive(:s3).and_return(s3_client_double)

    allow(s3_client_double).to receive(:list_objects).and_return([s3_object_double])
    allow(s3_client_double).to receive(:delete).with(key: anything).and_return(true)
    allow(s3_client_double).to receive(:get_as_io).with(key: anything).and_return(StringIO.new(submission_document))
  end

  it 'consumes submissions' do
    HmisExternalApis::PublishExternalFormsJob.new.perform(form_definition.id)
    submission_scope = form_definition.external_form_submissions
    expect do
      HmisExternalApis::ConsumeExternalFormSubmissionsJob.new.perform
    end.to change(submission_scope, :count).by(1)

    expect(s3_client_double).to have_received(:list_objects)

    submission = submission_scope.order(:id).last
    expect(submission.raw_data.to_json).to eq(submission_document)
  end
end
