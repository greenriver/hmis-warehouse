###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Uploads::DirectUploadType < BaseObject
    description 'Represents direct upload credentials'

    field :filename, String, null: false
    field :url, String, 'Upload URL', null: false
    field :headers, String,
          'HTTP request headers (JSON-encoded)',
          null: false
    field :blob_id, ID, 'Created blob record ID', null: false
    field :signed_blob_id, ID,
          'Created blob record signed ID',
          null: false
  end
end
