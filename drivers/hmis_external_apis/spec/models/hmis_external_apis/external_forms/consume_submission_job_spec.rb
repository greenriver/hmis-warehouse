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
  let(:encryption_key) do
    aes_key = OpenSSL::Random.random_bytes(32)

    GrdaWarehouse::RemoteCredentials::SymmetricEncryptionKey.where(slug: 'external_forms_shared_key').first_or_create! do |record|
      record.algorithm = 'aes-256-cbc'
      record.key_hex = aes_key.unpack1('H*')
    end
  end

  let(:captcha_score) { 0.65 }

  let(:submission_document) do
    form_definition_id = ProtectedId::Encoder.encode(form_definition.id)
    {
      your_name: 'test 1',
      form_definition_id: form_definition_id,
      captcha_score: encrypt(encryption_key, captcha_score),
    }.to_json
  end

  before do
    allow_any_instance_of(HmisExternalApis::ConsumeExternalFormSubmissionsJob).to receive(:s3).and_return(s3_client_double)

    allow(s3_client_double).to receive(:list_objects).and_return([s3_object_double])
    allow(s3_client_double).to receive(:delete).with(key: anything).and_return(true)
    allow(s3_client_double).to receive(:get_as_io).with(key: anything).and_return(StringIO.new(submission_document))
  end

  # emulate lambda behavior
  def encrypt(creds, plain_text)
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.encrypt
    cipher.key = [creds.key_hex].pack('H*') # Convert hex to binary

    iv = cipher.random_iv

    encrypted = cipher.update(plain_text.to_s) + cipher.final
    iv_hex = iv.unpack1('H*')
    encrypted_hex = encrypted.unpack1('H*')
    iv_hex + encrypted_hex
  end

  it 'consumes submissions' do
    HmisExternalApis::PublishExternalFormsJob.new.perform(form_definition.id)
    submission_scope = form_definition.external_form_submissions
    expect do
      HmisExternalApis::ConsumeExternalFormSubmissionsJob.new.perform(encryption_key: encryption_key)
    end.to change(submission_scope, :count).by(1)

    expect(s3_client_double).to have_received(:list_objects)

    submission = submission_scope.order(:id).last
    expect(submission.spam_score).to eq(captcha_score)
    expect(JSON.parse(submission.raw_data.to_json)).to eq(JSON.parse(submission_document))
  end
end
