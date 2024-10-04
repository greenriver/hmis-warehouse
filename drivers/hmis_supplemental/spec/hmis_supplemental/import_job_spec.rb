###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisSupplemental::ImportJob, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:user) }
  let(:client) { create(:hud_client, data_source: data_source) }

  let(:widget_key) { 'widget' }
  let(:widget_field) do
    JSON.parse <<~JSON
      {"key":"#{widget_key}","label":"The Widget","type":"float","multiValued":false}
    JSON
  end
  let(:widget_value) { 142.0 }

  let(:data_set) do
    HmisSupplemental::DataSet.create!(
      owner_type: 'client',
      slug: 'test',
      name: 'test',
      field_configs: [widget_field],
      remote_credential: create(:grda_remote_s3),
      data_source: data_source,
    )
  end

  let(:s3_client_double) { instance_double('AwsS3') }
  def run_job(data_set, content)
    allow(s3_client_double).to receive(:get_as_io).and_return(StringIO.new(content))
    allow_any_instance_of(GrdaWarehouse::RemoteCredentials::S3).to receive(:s3).and_return(s3_client_double)
    HmisSupplemental::ImportJob.new.perform(data_set: data_set)
  end

  def client_csv_string(personal_id:, key:, value:)
    [
      "personal_id,#{key}",
      [personal_id, value].join(','),
    ].join("\n")
  end

  describe 'client data set' do
    let(:csv_content) do
      client_csv_string(personal_id: client.personal_id, key: widget_key, value: widget_value)
    end
    it 'saves to CDEs' do
      value_scope = HmisSupplemental::FieldValue.where(data_set: data_set)
      expect do
        run_job(data_set, csv_content)
      end.to change(value_scope, :count).from(0).to(1)
      sample = value_scope.first
      expect(sample.data).to eq(widget_value)
      expect(sample.owner_key).to eq("client/#{client.personal_id}")
      expect(sample.field_key).to eq(widget_key)
      expect([sample]).to eq(value_scope.for_owner(client).to_a)
    end
  end
end
