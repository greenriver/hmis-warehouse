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

  # `belongs_to :user` is required (belongs_to_required_by_default). ActiveStorage's
  # `attach` performs an implicit, non-`validate: false` save when the record is
  # persisted-and-unchanged; without a valid `user` that implicit save silently fails
  # validation, the attachment upload gets deferred to the later `save!(validate: false)`
  # in `copy_to_s3!`, and by then the Tempfile has already been closed/unlinked.
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

  it 'migrates content to S3 and nulls it' do
    export = build_export
    export.save!(validate: false)
    export.copy_to_s3!
    export.reload
    expect(export.research_export_file).to be_attached
    expect(export.content).to be_nil
  end

  describe '.unprocessed_s3_migration' do
    it 'excludes exports with an attached file and includes pending content-only exports' do
      migrated = build_export
      migrated.save!(validate: false)
      migrated.copy_to_s3!

      pending = build_export
      pending.save!(validate: false)

      ids = described_class.unprocessed_s3_migration.pluck(:id)
      expect(ids).to include(pending.id)
      expect(ids).not_to include(migrated.id)
    end
  end
end
