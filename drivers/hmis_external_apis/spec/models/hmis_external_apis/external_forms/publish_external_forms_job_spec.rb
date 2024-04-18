###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'HmisExternalApis::PublishExternalFormsJob', type: :model do
  let!(:data_source) { create :hmis_data_source }
  let(:json_definition) do
    <<~JSON
      {
        "name": "Test form",
        "item": [
          {
            "type": "GROUP",
            "link_id": "group_1",
            "text": "Test group",
            "item": [
              {
                "link_id": "your_name",
                "mapping": {"custom_field_key": "your_name"},
                "required": true,
                "type": "STRING",
                "text": "Your Name"
              },
              {
                "link_id": "display_1",
                "type": "DISPLAY",
                "text": "Some informational content here",
                "enable_behavior": "ALL",
                "enable_when": [
                  {
                    "question": "your_name",
                    "operator": "EQUAL",
                    "answer_code": "robot"
                  }
                ]
              },
              {
                "link_id": "a_radio_choice",
                "mapping": {"custom_field_key": "a_radio_choice"},
                "required": true,
                "type": "CHOICE",
                "component": "RADIO_BUTTONS",
                "text": "Are you testing a form?",
                "pick_list_options": [
                  {
                    "code": "yes",
                    "label": "Yes"
                  },
                  {
                    "code": "no",
                    "label": "No"
                  }
                ]
              },
              {
                "link_id": "a_select_choice",
                "mapping": {"custom_field_key": "a_select_choice"},
                "type": "CHOICE",
                "component": "DROPDOWN",
                "text": "How many tests?",
                "pick_list_options": [
                  {
                    "code": "not_many",
                    "label": "Not many"
                  },
                  {
                    "code": "a_whole_bunch",
                    "label": "A whole bunch"
                  }
                ]
              },
              {
                "link_id": "a_checkbox",
                "mapping": {"custom_field_key": "a_checkbox"},
                "type": "BOOLEAN",
                "component": "CHECKBOX",
                "text": "I understand that this is a test"
              }
            ]
          }
        ]
      }
    JSON
  end

  let(:form_definition) do
    create(:hmis_external_form_definition, definition: JSON.parse(json_definition))
  end

  before(:each) do
    {
      site_logo_alt: 'test site alt',
      site_logo_url: 'logo.png',
      site_logo_width: 100,
      site_logo_height: 100,
      recaptcha_key: 'fakekey',
      presign_url: 'http://example.com',
      csp_content: ["default-src 'self'"],
    }.each do |key, value|
      AppConfigProperty.create!(key: "external_forms/#{key}", value: value)
    end
  end

  it 'publishing populates the content and key' do
    publication_scope = form_definition.external_form_publications
    expect do
      HmisExternalApis::PublishExternalFormsJob.new.perform(form_definition.id)
    end.to change(publication_scope, :count).by(1)

    publication = publication_scope.order(:id).last

    expect(publication.content).not_to be_nil
    # expect content to be valid HTML doc
    doc = Nokogiri::HTML5(publication.content)
    expect(doc.errors).to be_empty

    expect(publication.content_digest).not_to be_nil
    # expect(publication.object_key).not_to be_nil
  end
end
