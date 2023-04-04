###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Uploads::DirectUploadInputType < BaseInputObject
    description 'File information required to prepare a direct upload'

    argument :filename, String, 'Original file name', required: true
    argument :byte_size, Int, 'File size (bytes)', required: true
    argument :checksum, String, 'MD5 file checksum as base64', required: true
    argument :content_type, String, 'File content type', required: true
  end
end
