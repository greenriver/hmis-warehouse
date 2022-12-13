# inspired by
# https://evilmartians.com/chronicles/active-storage-meets-graphql-direct-uploads

module Mutations
  class CreateDirectUpload < BaseMutation
    argument :input, Types::DirectUploadInputType, required: true
    type Types::DirectUploadType

    def resolve(input:)
      blob = ActiveStorage::Blob.create_before_direct_upload!(input.to_h)
      {
        url: blob.service_url_for_direct_upload,
        # NOTE: we pass headers as JSON since they have no schema
        headers: blob.service_headers_for_direct_upload.to_json,
        blob_id: blob.id,
        signed_blob_id: blob.signed_id,
        filename: input.filename,
      }
    end
  end
end
