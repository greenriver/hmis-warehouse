###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# inspired by
# https://evilmartians.com/chronicles/active-storage-meets-graphql-direct-uploads

module Mutations
  class CreateDirectUpload < BaseMutation
    argument :input, Types::Uploads::DirectUploadInputType, required: true
    type Types::Uploads::DirectUploadType

    def resolve(input:)
      ActiveStorage::Blob.create_before_direct_upload!(**input.to_h)
    end
  end
end
