###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TxClientReports::ResearchExports::Export, type: :model do
  let(:bytes) { 'xlsxbytes' * 40 }
  let(:user) { create(:user) }

  def build_export
    described_class.new(user: user, content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', content: bytes)
  end

  it 'exposes file_data with attachment fallback' do
    export = build_export
    expect(export.file_data).to eq(bytes)
    export.content = nil
    export.save!(validate: false)
    export.research_export_file.attach(io: StringIO.new(bytes), filename: 'export.xlsx', content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    expect(export.file_data).to eq(bytes)
  end
end
