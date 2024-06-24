###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'JSON Schema validation', type: :model do
  let(:schema) do
    'drivers/hmis_external_apis/public/schemas/form_definition.json'
  end

  describe 'against a valid definition' do
    let(:document) do
      {"item"=>[{"text"=>"hello world", "type"=>"STRING", "link_id"=>"node1"}]}
    end
    it 'should be valid' do
      expect(HmisExternalApis::JsonValidator.perform(document, schema)).to be_empty
    end
  end

  describe 'against a definition with an invalid link-id' do
    let(:document) do
      {"item"=>[{"text"=>"hello world", "type"=>"STRING", "link_id"=>"has-hyphens"}]}
    end
    it 'should be invalid' do
      expect(HmisExternalApis::JsonValidator.perform(document, schema)).to include(a_string_matching(/property '\/item\/0\/link_id' does not match pattern/))
    end
  end

  describe 'against a definition with invalid properties' do
    let(:document) do
      { "item"=>[ {"text"=>"hello world", "type"=>"STRING", "link_id"=>"node1", "martian"=>"hello earthlings"} ] }
    end
    it 'should be invalid' do
      expect(HmisExternalApis::JsonValidator.perform(document, schema)).to include(a_string_matching(/property '\/item\/0\/martian' is invalid/))
    end
  end
end
