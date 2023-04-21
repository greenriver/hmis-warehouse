###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# common behavior for referral processing
module HmisExternalApis
  module ExternallyIdentifiedMixin
    extend ActiveSupport::Concern
    class_methods do
      def find_by_external_id(cred:, id:)
        id_scope = HmisExternalApis::ExternalId
          .where({ value: id, remote_credential: cred, source_type: name })

        # external id values are not unique, to_h will choose the record with the earliest timestamp
        # https://github.com/greenriver/hmis-warehouse/pull/2955/files#r1166824257
        where(id: id_scope.select(:source_id))
          .order_by_created_at
          .order(:id)
          .first!
      end
    end
  end
end
