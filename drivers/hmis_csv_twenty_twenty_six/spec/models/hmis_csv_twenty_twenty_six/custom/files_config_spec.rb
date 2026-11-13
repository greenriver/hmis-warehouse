###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Custom::FilesConfig do
  describe '#hmis_owned_filenames' do
    it 'includes only the filenames of hmis_owned definitions' do
      files_config = described_class.new
      hmis_owned_filenames = files_config.hmis_owned_filenames

      expect(hmis_owned_filenames).to contain_exactly('CustomDataElement.csv', 'CustomDataElementDefinition.csv')
    end
  end
end
