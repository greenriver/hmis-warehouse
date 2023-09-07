###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::ProjectsCrossWalkFetcher, type: :model do
  before { create(:hmis_data_source) }

  it 'runs' do
    subject.run!
  end
end
