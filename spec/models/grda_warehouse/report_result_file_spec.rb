###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ReportResultFile, type: :model do
  let(:bytes) { 'reportzip' * 30 }

  def build_file
    described_class.new(file: 'result.zip', content_type: 'application/zip', content: bytes)
  end

  it 'exposes file_data with attachment fallback' do
    file = build_file
    expect(file.file_data).to eq(bytes)
    file.content = nil
    file.save!(validate: false)
    file.report_result_file.attach(io: StringIO.new(bytes), filename: 'result.zip', content_type: 'application/zip')
    expect(file.file_data).to eq(bytes)
  end
end
