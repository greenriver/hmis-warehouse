###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'zip'
require 'csv'

RSpec.describe HmisExternalApis::AcHmis::Exporters::HmisExportFetcher, type: :model do
  before { create(:hmis_data_source) }

  it 'generates a zip file with 2026 fields' do
    subject.run!
    expect(subject.content).to start_with('PK')

    zip_data = StringIO.new(subject.content)
    csv_headers = {}

    Zip::InputStream.open(zip_data) do |io|
      while (entry = io.get_next_entry)
        next unless entry.name.end_with?('.csv')

        csv_headers[entry.name] = entry.get_input_stream.read.lines.first
      end
    end

    expect(csv_headers['Enrollment.csv']).not_to be_nil, 'Enrollment.csv not found in zip file'
    enrollment_headers = CSV.parse_line(csv_headers['Enrollment.csv'])
    expect(enrollment_headers).to include('MentalHealthConsultation')

    expect(csv_headers['Client.csv']).not_to be_nil, 'Client.csv not found in zip file'
    client_headers = CSV.parse_line(csv_headers['Client.csv'])
    expect(client_headers).to include('Sex')
  end
end
