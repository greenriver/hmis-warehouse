###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Loader::Loader, type: :model do
  describe '#expand' do
    include_examples 'an HMIS CSV loader that expands into @local_path'
  end
end
