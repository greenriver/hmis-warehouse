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

    # Object is a client. This type will extract the images form the client

    def content_type
      # ! Fix this to take into account file format
      'image/png'
    end

    def base64
      ::Base64.encode64(object.image)
    end
  end
end
