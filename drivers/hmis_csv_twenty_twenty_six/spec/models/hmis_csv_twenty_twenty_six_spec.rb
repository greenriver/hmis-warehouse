###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix do
  describe '.hmis_owned_filenames' do
    it 'delegates to the custom files config' do
      expect(described_class.hmis_owned_filenames).to eq(described_class.custom_files_config.hmis_owned_filenames)
    end

    it 'includes the CustomDataElement files' do
      expect(described_class.hmis_owned_filenames).to contain_exactly('CustomDataElement.csv', 'CustomDataElementDefinition.csv')
    end
  end
end
