###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ClientImage < Types::BaseObject
    description 'Client Image'
    field :id, ID, null: false
    field :content_type, String, null: false
    field :base64, Types::Base64, null: false

    # Object is a GrdaWarehouse::ClientFile

    def content_type
      object.content_type || 'image/jpeg'
    end

    def base64
      ::Base64.encode64(object.download)
    end
  end
end
