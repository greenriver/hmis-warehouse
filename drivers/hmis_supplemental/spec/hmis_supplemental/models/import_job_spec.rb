###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisSupplemental::ImportJob, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:user) }

  let(:widget_key) { data_set.fields.first.key }
  let(:widget_value) { 142.0 }

  let(:data_set) do
    create(:hmis_supplemental_data_set, data_source: data_source)
  end

  let(:s3_client_double) { instance_double('AwsS3') }
  def run_job(data_set, content)
    allow(s3_client_double).to receive(:get_as_io).and_return(StringIO.new(content))
    allow_any_instance_of(GrdaWarehouse::RemoteCredentials::S3).to receive(:s3).and_return(s3_client_double)
    HmisSupplemental::ImportJob.new.perform(data_set: data_set)
  end

  def csv_string(rows)
    keys = rows.first.last.keys
    raise if keys.empty?

    CSV.generate(headers: true) do |csv|
      csv << ['personal_id'] + keys
      rows.each do |client, values|
        csv << [client.personal_id] + values.values_at(*keys)
      end
    end
  end

  def deterministic_random_string(seed, length = 10)
    rng = Random.new(seed)
    characters = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    Array.new(length) { characters[rng.rand(characters.size)] }.join
  end

  def fake_field_value(field)
    case field.type
    when 'string', 'id'
      Faker::Alphanumeric.alphanumeric(number: 5)
    when 'int'
      Faker::Number.between(from: 1, to: 10).to_i
    when 'float'
      # 2 decimals seems like reasonable default. Could be configurable
      Faker::Number.between(from: 1.5, to: 10.5).round(2)
    when 'boolean'
      Faker::Boolean.boolean
    when 'date'
      today = Date.current
      Faker::Date.between(from: today - 10.years, to: today).to_fs(:db)
    else
      raise "unknown type: #{field.type}"
    end
  end

  let(:fields) { data_set.fields }
  describe 'client data set' do
    let(:clients) do
      2.times.map { create(:hud_client, data_source: data_source) }
    end

    describe 'imports all field values' do
      let(:rows) do
        clients.map do |client|
          values = fields.to_h do |field|
            if field.multi_valued
              value = 2.times.map { fake_field_value(field) }.join('|')
            else
              value = fake_field_value(field)
            end
            [field.key, value]
          end
          [client, values]
        end
      end

      it 'saves to all values' do
        value_scope = HmisSupplemental::FieldValue.where(data_set: data_set)

        expect do
          run_job(data_set, csv_string(rows))
        end.to change(value_scope, :count).from(0).to(data_set.fields.size * clients.size)

        rows.each do |client, row|
          data_set.field_values.for_owner(client).each do |value|
            field = fields.detect { |f| f.key == value.field_key }
            expected = row[field.key]
            expected = expected.split('|') if field.multi_valued
            expect(value.data).to eq(expected)
            expect(value.owner_key).to eq("client/#{client.personal_id}")
          end
        end
      end
    end

    describe 'importing duplicate field values' do
      let(:client) do
        create(:hud_client, data_source: data_source)
      end

      let(:one_field) { fields.reject(&:multi_valued).first }
      let(:multi_field) { fields.detect(&:multi_valued) }
      let(:rows) do
        2.times.map do
          [
            client,
            {
              one_field.key => fake_field_value(one_field),
              multi_field.key => fake_field_value(multi_field),
            },
          ]
        end
      end

      it 'saves the multi and single fields values' do
        value_scope = HmisSupplemental::FieldValue.where(data_set: data_set)

        expect do
          run_job(data_set, csv_string(rows))
        end.to change(value_scope, :count).from(0).to(2)

        # for single fields, we should capture the first value
        saved = data_set.field_values.for_owner(client).where(field_key: one_field.key).first.data
        expected = rows.dig(0, 1, one_field.key)
        expect(saved).to eq(expected)

        # for multi fields, we should capture all values
        saved = data_set.field_values.for_owner(client).where(field_key: multi_field.key).first.data
        expected = rows.map { |row| row.dig(1, multi_field.key) }
        expect(saved).to eq(expected)
      end
    end
  end
end
