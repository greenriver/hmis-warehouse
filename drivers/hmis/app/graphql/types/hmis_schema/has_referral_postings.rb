###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasReferralPostings
      extend ActiveSupport::Concern

      class_methods do
        def referral_postings_field(name, description = nil, type: Types::HmisSchema::ReferralPosting.page_type, **override_options, &block)
          default_field_options = { type: type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            filters_argument Types::HmisSchema::ReferralPosting
            instance_eval(&block) if block_given?
          end
        end
      end

      # TODO(#186102846) support filtering
      def scoped_referral_postings(scope, sort_order: nil, dangerous_skip_permission_check: false, filters: nil)
        # note: viewability is based on the project that is receiving the referral
        scope = scope.viewable_by(current_user) unless dangerous_skip_permission_check

        Rails.logger.info(">>> filters #{filters.inspect}")
        scope = scope.preload(referral: { household_members: :client }).
          preload(:unit_type).
          preload(:status_note_updated_by).
          preload(:status_updated_by).
          preload(:project)

        scope = scope.where(status: filters.status) if filters&.status.present? # make sure it doesnt override previous tho
        sort_order.present? ? scope.sort_by_option(sort_order) : scope
      end
    end
  end
end
