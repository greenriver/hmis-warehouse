###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Form::FormProcessor, type: :model do
  include_context 'hmis base setup'
  include_context 'file upload setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }

  let(:definition_json) do
    {
      "item": [
        {
          "type": 'STRING',
          "link_id": 'unrelated',
          "text": 'Another assessment field',
          "mapping": {
            "custom_field_key": 'unrelated',
          },
        },
        {
          "type": 'FILE',
          "link_id": 'file_upload',
          "repeats": true,
          "text": 'Here is where you can upload a file',
          "mapping": {
            "custom_field_key": 'file_upload',
          },
        },
      ],
    }
  end
  let!(:definition) { create :hmis_form_definition, role: :CUSTOM_ASSESSMENT, definition: definition_json }
  let!(:file_cded) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'file_upload', data_source: ds1, field_type: :file, repeats: true }
  let!(:string_cded) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'unrelated', data_source: ds1, field_type: :string }

  let!(:file1) { File.open('drivers/hmis/spec/fixtures/files/TEST_PDF.pdf') }
  let!(:blob1) do
    ActiveStorage::Blob.create_and_upload!(
      io: file1,
      filename: 'TEST_PDF.pdf',
      content_type: 'application/pdf',
    )
  end
  let!(:file2) { File.open('drivers/hmis/spec/fixtures/files/client_photo_00001.jpg') }
  let!(:blob2) do
    ActiveStorage::Blob.create_and_upload!(
      io: file2,
      filename: 'client_photo_00001.jpeg',
      content_type: 'image/jpeg',
    )
  end

  it 'processes nil file correctly' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: definition, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'file_upload' => nil,
      'unrelated' => nil,
    }
    expect do
      assessment.form_processor.run!(user: hmis_user)
      assessment.save_not_in_progress
    end.not_to change(Hmis::Hud::CustomDataElement, :count)
  end

  it 'processes newly submitted file' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: definition, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'file_upload' => blob1.signed_id.to_s,
      'unrelated' => 'Some string',
    }

    expect do
      assessment.form_processor.run!(user: hmis_user)
      assessment.save_not_in_progress
    end.to change(Hmis::Hud::CustomDataElement, :count).by(2)

    saved_file_record = Hmis::Hud::CustomDataElement.of_type(file_cded).sole.value_file
    expect(saved_file_record.client_file.blob).to eq(blob1)
    expect(saved_file_record.client).to eq(c1)
    expect(saved_file_record.enrollment).to eq(e1)
    expect(saved_file_record.name).to eq('TEST_PDF.pdf')
  end

  it 'processes re-submit when file value has not changed' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: definition, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'file_upload' => blob1.signed_id.to_s,
      'unrelated' => 'first value',
    }
    assessment.form_processor.run!(user: hmis_user)
    assessment.save_not_in_progress
    saved_file_record = Hmis::Hud::CustomDataElement.of_type(file_cded).sole.value_file

    expect do
      assessment.reload.form_processor.hud_values = {
        'file_upload' => saved_file_record.id.to_s,
        'unrelated' => 'second value!',
      }
      assessment.form_processor.run!(user: hmis_user)
      assessment.form_processor.save!
      assessment.save_not_in_progress
      assessment.reload
      saved_file_record.reload
    end.to not_change(Hmis::Hud::CustomDataElement, :count).
      and not_change(saved_file_record, :deleted_at).
      and not_change(saved_file_record, :updated_at)

    expect(Hmis::Hud::CustomDataElement.of_type(string_cded).sole.value_string).to eq('second value!')
  end

  it 'adds a file to an existing assessment' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: definition, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'file_upload' => blob1.signed_id.to_s,
      'unrelated' => 'first value',
    }
    assessment.form_processor.run!(user: hmis_user)
    assessment.save_not_in_progress
    saved_file_record = Hmis::Hud::CustomDataElement.of_type(file_cded).sole.value_file

    expect do
      assessment.reload.form_processor.hud_values = {
        'file_upload' => [saved_file_record.id.to_s, blob2.signed_id.to_s],
        'unrelated' => 'first value',
      }
      assessment.form_processor.run!(user: hmis_user)
      assessment.form_processor.save!
      assessment.save_not_in_progress
      assessment.reload
      saved_file_record.reload
    end.to change(Hmis::Hud::CustomDataElement, :count).by(1).
      and not_change(saved_file_record, :deleted_at).
      and not_change(saved_file_record, :updated_at)

    file_cdeds = Hmis::Hud::CustomDataElement.of_type(file_cded)
    expect(file_cdeds.count).to eq(2)
    expect(file_cdeds.first.value_file).to eq(saved_file_record)
    expect(file_cdeds.second.value_file.client_file.blob).to eq(blob2)
    expect(file_cdeds.second.value_file.name).to eq('client_photo_00001.jpeg')
  end

  it 'removes a previously uploaded file' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: definition, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'file_upload' => [blob1.signed_id.to_s, blob2.signed_id.to_s],
      'unrelated' => 'first value',
    }
    expect do
      assessment.form_processor.run!(user: hmis_user)
      assessment.save_not_in_progress
    end.to change(Hmis::Hud::CustomDataElement, :count).by(3).
      and change(Hmis::File, :count).by(2)

    saved_file1 = Hmis::Hud::CustomDataElement.of_type(file_cded).first.value_file
    saved_file2 = Hmis::Hud::CustomDataElement.of_type(file_cded).second.value_file

    expect do
      assessment.reload.form_processor.hud_values = {
        'file_upload' => [saved_file1.id.to_s], # remove one file
        'unrelated' => 'first value',
      }
      assessment.form_processor.run!(user: hmis_user)
      assessment.form_processor.save!
      assessment.save_not_in_progress
      assessment.reload
      saved_file1.reload
      saved_file2.reload
    end.to change(Hmis::Hud::CustomDataElement, :count).from(3).to(2).
      and not_change(saved_file1, :deleted_at).
      and not_change(saved_file1, :updated_at).
      and change(saved_file2, :deleted_at)

    file_cdeds = Hmis::Hud::CustomDataElement.of_type(file_cded)
    expect(file_cdeds.count).to eq(1)
    expect(file_cdeds.sole.value_file).to eq(saved_file1)
  end

  context 'with existing file record' do
    let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:existing_file_record) { create :file, client: c2, blob: blob1, user_id: hmis_user.id }

    it 'does not allow saving by file ID if not associated with this CustomAssessment already' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: definition, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'file_upload' => [existing_file_record.id.to_s],
      }
      expect do
        assessment.form_processor.run!(user: hmis_user)
        assessment.save_not_in_progress
      end.to raise_error(RuntimeError, /Access denied/).
        and not_change(Hmis::Hud::CustomDataElement, :count)
    end
  end
end
