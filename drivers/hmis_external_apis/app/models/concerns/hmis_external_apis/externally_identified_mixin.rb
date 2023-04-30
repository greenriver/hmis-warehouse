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
      # find the first record with an external id namespace:value
      # @param namespace [String]
      # @param value[String]
      # @return [ApplicationRecord, nil]
      def first_by_external_id(namespace:, value:)
        id_scope = HmisExternalApis::ExternalId
          .where({ value: value, namespace: namespace, source_type: name })

        where(id: id_scope.select(:source_id)).order(:id).first
      end
    end
  end
end
