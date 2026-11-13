###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::DashboardExportFile, type: :model do
  let(:bytes) { 'zipbytes' * 50 }

  def build_file
    described_class.new(file: 'export.zip', content_type: 'application/zip', content: bytes)
  end

  it 'exposes file_data with attachment fallback' do
    file = build_file
    expect(file.file_data).to eq(bytes)
    file.save!(validate: false)
    file.content = nil
    file.dashboard_export_file.attach(io: StringIO.new(bytes), filename: 'export.zip', content_type: 'application/zip')
    file.save!(validate: false)
    expect(file.file_data).to eq(bytes)
  end
end
