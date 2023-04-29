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
      def first_by_external_id(namespace:, id:)
        id_scope = HmisExternalApis::ExternalId
          .where({ value: id, namespace: namespace, source_type: name })

        where(id: id_scope.select(:source_id)).order(:id).first
      end
    end
  end
end
