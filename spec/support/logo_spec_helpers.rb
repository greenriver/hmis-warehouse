###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module LogoSpecHelpers
  # Creates the attachment without running theme validation, as a logo stored earlier would be
  def store_unvalidated_logo(theme, slot, content_type:, body: 'x', filename: 'file.bin')
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(body), filename: filename, content_type: content_type)
    ActiveStorage::Attachment.create!(name: slot, record: theme, blob: blob)
  end
end

RSpec.configure do |config|
  config.include LogoSpecHelpers
end
