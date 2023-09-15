###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::ProjectsCrossWalkFetcher, type: :model do
  before { create(:hmis_data_source) }

  it 'provides projects' do
    subject.run!
    result = CSV.parse(subject.projects_csv_stream.read, headers: true)

    expect(result.to_a).to eq(
      [
        ['Warehouse ID', 'HMIS ProjectID', 'Project Name', 'HMIS Organization ID', 'Organization Name', 'Data Source', 'Date Updated'],
      ],
    )
  end

  it 'provides organizations' do
    subject.run!
    result = CSV.parse(subject.orgs_csv_stream.read, headers: true)

    expect(result.to_a).to eq(
      [
        ['Warehouse ID', 'HMIS Organization ID', 'Organization Name', 'Data Source', 'Date Updated'],
      ],
    )
  end
end
