###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'HmisExternalApis::StaticPages::FormDefinition', type: :model do
  subject(:form_definition) do
    create(:hmis_external_apis_static_pages_form_definition)
  end

  it 'publishing populates the content and key' do
    form_definition.publish!
    form_definition.reload
    expect(form_definition.content).not_to be_nil
    # expect content to be valid HTML doc
    doc = Nokogiri::HTML5(form_definition.content)
    expect(doc.errors).to be_empty

    expect(form_definition.content_digest).not_to be_nil
    # expect(form_definition.object_key).not_to be_nil
  end
end
