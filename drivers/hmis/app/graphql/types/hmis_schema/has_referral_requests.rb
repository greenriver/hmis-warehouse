###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasReferralRequests
      extend ActiveSupport::Concern

      class_methods do
        def referral_requests_field(name, description = nil, type: Types::HmisSchema::ReferralRequest.page_type, **override_options, &block)
          default_field_options = { type: type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_referral_requests_with_loader(association_name, **args)
        scope = scoped_referral_requests(HmisExternalApis::AcHmis::ReferralRequest.all, **args)
        load_ar_association(object, association_name, scope: scope)
      end

      def scoped_referral_requests(scope, sort_order: nil)
        # not sure what permissions are relevant
        # scope = scope.viewable_by(current_user)
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
