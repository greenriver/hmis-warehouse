###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'HmisExternalApis::TcHmis::Importers', type: :model do
  include AcHmisLoaderHelpers

  describe 'Fail CI and force us to do housekeeping' do
    TodoOrDie('Remove TcHmis importers', by: '2024-12-01')
  end
end
