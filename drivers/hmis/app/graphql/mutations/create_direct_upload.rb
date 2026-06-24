###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# inspired by
# https://evilmartians.com/chronicles/active-storage-meets-graphql-direct-uploads

module Mutations
  class CreateDirectUpload < BaseMutation
    argument :input, Types::Uploads::DirectUploadInputType, required: true
    type Types::Uploads::DirectUploadType

    def resolve(input:)
      # Direct upload only stages a blob in storage. Attaching the blob to a record is authorized
      # separately (e.g. submitForm, updateClientImage). Additional check here just to be safe.
      access_denied! unless authorized_for_direct_upload?

      blob = ActiveStorage::Blob.create_before_direct_upload!(**input.to_h)
      {
        url: blob.service_url_for_direct_upload,
        # NOTE: we pass headers as JSON since they have no schema
        headers: blob.service_headers_for_direct_upload.to_json,
        signed_blob_id: blob.signed_id(expires_in: 8.hours),
        filename: input.filename,
      }
    end

    private

    def authorized_for_direct_upload?
      # File uploads (assessment attachments, client files, etc.)
      return true if policy_for(Hmis::File, policy_type: :hmis_file).can_upload_files?

      # Client profile image upload uses updateClientImage, which only requires ability to edit the client
      policy_for(Hmis::Hud::Client, policy_type: :hmis_client).can_edit?
    end
  end
end
