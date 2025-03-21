###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::HmisExportFetcher, type: :model do
  before { create(:hmis_data_source) }

  it 'makes a zipped file' do
    subject.run!
    expect(subject.export.hmis_zip.download).to start_with('PK')
  end
end
