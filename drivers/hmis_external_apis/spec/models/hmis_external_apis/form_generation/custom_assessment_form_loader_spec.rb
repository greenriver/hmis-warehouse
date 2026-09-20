###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::FormGeneration::CustomAssessmentFormLoader, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:identifier) { 'mar_test_form' }
  let(:definition_json) do
    {
      'name' => 'Test Form',
      'item' => [
        {
          'type' => 'STRING',
          'link_id' => 'q1',
          'text' => 'Question 1',
          'mapping' => { 'custom_field_key' => 'mar_q1_key' },
        },
      ],
    }
  end

  def write_form_json(dir, form_identifier, payload)
    File.write(File.join(dir, "#{form_identifier}.json"), JSON.pretty_generate(payload))
  end

  def published_definition
    Hmis::Form::Definition.in_data_source(data_source.id).find_by(identifier: identifier, status: Hmis::Form::Definition::PUBLISHED)
  end

  describe '#call' do
    context 'when publishing a new form' do
      it 'creates a published definition and mints CDEDs for unmapped keys' do
        Dir.mktmpdir do |dir|
          write_form_json(dir, identifier, definition_json)

          result = described_class.call(dir: dir, data_source_id: data_source.id)

          expect(result[:success]).to eq(true)
          expect(published_definition).to be_present
          expect(published_definition.version).to eq(0)

          cded = Hmis::Hud::CustomDataElementDefinition.find_by(key: 'mar_q1_key', data_source: data_source)
          expect(cded).to be_present
        end
      end
    end

    context 'when dry_run is true' do
      it 'reports what would happen without writing anything' do
        Dir.mktmpdir do |dir|
          write_form_json(dir, identifier, definition_json)

          result = described_class.call(dir: dir, data_source_id: data_source.id, dry_run: true)

          expect(result[:success]).to eq(true)
          expect(result[:results].sole).to have_attributes(action: :publish, detail: 'would publish v0')
          expect(published_definition).to be_nil
        end
      end
    end

    context 'when a published version already exists' do
      let!(:existing_published) do
        create(:hmis_form_definition, identifier: identifier, data_source: data_source, role: 'CUSTOM_ASSESSMENT', version: 0, status: Hmis::Form::Definition::PUBLISHED)
      end

      it 'retires the old version and publishes the next version' do
        Dir.mktmpdir do |dir|
          write_form_json(dir, identifier, definition_json)

          result = described_class.call(dir: dir, data_source_id: data_source.id)

          expect(result[:success]).to eq(true)
          versions = Hmis::Form::Definition.in_data_source(data_source.id).where(identifier: identifier).order(:version)
          expect(versions.map(&:status)).to eq(['retired', 'published'])
          expect(versions.last.version).to eq(1)
        end
      end
    end

    context 'when a draft exists for the identifier (customer is editing in Form Builder)' do
      let!(:published) do
        create(:hmis_form_definition, identifier: identifier, data_source: data_source, role: 'CUSTOM_ASSESSMENT', version: 0, status: Hmis::Form::Definition::PUBLISHED)
      end
      let!(:draft) do
        create(:hmis_form_definition, identifier: identifier, data_source: data_source, role: 'CUSTOM_ASSESSMENT', version: 1, status: Hmis::Form::Definition::DRAFT)
      end

      it 'reports the draft without deleting it in dry_run mode' do
        Dir.mktmpdir do |dir|
          write_form_json(dir, identifier, definition_json)

          result = described_class.call(dir: dir, data_source_id: data_source.id, dry_run: true)

          expect(result[:results].map(&:action)).to include(:draft_exists)
          expect(Hmis::Form::Definition.exists?(draft.id)).to eq(true)
        end
      end

      it 'deletes the draft and publishes a new version from the generated JSON' do
        Dir.mktmpdir do |dir|
          write_form_json(dir, identifier, definition_json)

          result = described_class.call(dir: dir, data_source_id: data_source.id)

          expect(result[:success]).to eq(true)
          expect(Hmis::Form::Definition.exists?(draft.id)).to eq(false)
          expect(published_definition.version).to eq(1)
        end
      end
    end

    context 'when re-publishing the same custom_field_key' do
      it 'reuses the existing CDED instead of creating a duplicate' do
        Dir.mktmpdir do |dir|
          write_form_json(dir, identifier, definition_json)
          described_class.call(dir: dir, data_source_id: data_source.id)
          described_class.call(dir: dir, data_source_id: data_source.id)

          expect(Hmis::Hud::CustomDataElementDefinition.where(key: 'mar_q1_key', data_source: data_source).count).to eq(1)
        end
      end
    end

    context 'when the JSON role does not match CUSTOM_ASSESSMENT' do
      it 'records an error and does not publish' do
        Dir.mktmpdir do |dir|
          envelope = { 'identifier' => identifier, 'title' => 'Test Form', 'role' => 'UPDATE', 'definition' => definition_json }
          write_form_json(dir, identifier, envelope)

          result = described_class.call(dir: dir, data_source_id: data_source.id)

          expect(result[:success]).to eq(false)
          expect(result[:errors].sole.detail).to match(/is not CUSTOM_ASSESSMENT/)
          expect(published_definition).to be_nil
        end
      end
    end

    context 'with only:' do
      it 'imports just the specified identifiers' do
        Dir.mktmpdir do |dir|
          write_form_json(dir, identifier, definition_json)
          write_form_json(dir, 'mar_other_form', definition_json.merge('name' => 'Other Form'))

          result = described_class.call(dir: dir, data_source_id: data_source.id, only: [identifier])

          expect(result[:results].map(&:identifier)).to eq([identifier])
          expect(published_definition).to be_present
          expect(Hmis::Form::Definition.in_data_source(data_source.id).where(identifier: 'mar_other_form')).not_to exist
        end
      end
    end

    context 'when data_source_id is not given and multiple HMIS data sources exist' do
      let!(:data_source_one) { create(:hmis_data_source) }
      let!(:data_source_two) { create(:hmis_data_source) }

      it 'raises a helpful error' do
        Dir.mktmpdir do |dir|
          write_form_json(dir, identifier, definition_json)

          expect { described_class.call(dir: dir) }.to raise_error(/Multiple HMIS data sources exist/)
        end
      end
    end
  end
end
