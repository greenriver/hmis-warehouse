###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module GrdaWarehouse
    module RemoteCredentialExtension
      extend ActiveSupport::Concern

      included do
        has_many :external_ids,
                 class_name: 'HmisExternalApis::ExternalId',
                 foreign_key: :remote_credential_id,
                 dependent: :restrict_with_exception
      end
    end
  end
end
