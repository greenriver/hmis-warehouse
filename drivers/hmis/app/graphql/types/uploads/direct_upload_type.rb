###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Uploads::DirectUploadType < BaseObject
    description 'Represents direct upload credentials'

    # underlying object is a ActiveStorage::Blob

    field :filename, String, null: false
    field :url, String, 'Upload URL', null: false
    field :headers, String,
          'HTTP request headers (JSON-encoded)',
          null: false
    field :blob_id, ID, 'Created blob record ID', null: false
    field :signed_blob_id, ID,
          'Created blob record signed ID',
          null: false

    def url
      object.service_url_for_direct_upload
    end

    def headers
      # NOTE: we pass headers as JSON since they have no schema
      object.service_headers_for_direct_upload.to_json
    end

    def blob_id
      object.id
    end

    def signed_blob_id
      object.signed_id
    end

    def filename
      object.filename
    end
  end
end
