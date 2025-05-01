###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCeOpportunities
      extend ActiveSupport::Concern

      include ::Hmis::Concerns::HmisArelHelper

      class_methods do
        def ce_opportunities_field(name = :ce_opportunities, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = { type: Types::HmisSchema::CeOpportunity.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::CeOpportunitySortOption, required: false
            filters_argument HmisSchema::CeOpportunity, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      included do
        def resolve_ce_opportunities(scope = object.ce_opportunities, **args)
          scoped_ce_opportunities(scope, **args)
        end
      end

      private

      def scoped_ce_opportunities(scope, user: current_user, sort_order: :date_available_earliest_first, filters: nil)
        raise unless Hmis::Ce.configuration.enabled? # TODO(#7506) permissions

        scope = scope.viewable_by(user)

        scope = scope.where(status: filters&.status) if filters.respond_to?(:status) && filters&.status.present?
        scope = scope.where(project_id: filters&.project) if filters.respond_to?(:project) && filters&.project.present?
        scope = scope.joins(:project).where(p_t[:project_type].in(filters&.project_type)) if filters.respond_to?(:project_type) && filters&.project_type.present?
        scope = scope.joins(project: :organization).where(o_t[:id].in(filters&.organization)) if filters.respond_to?(:organization) && filters&.organization.present?
        scope = scope.available_on_date(filters&.available_on_date) if filters.respond_to?(:available_on_date) && filters&.available_on_date.present?
        scope = scope.where(workflow_template_identifier: filters&.workflow_template) if filters.respond_to?(:workflow_template) && filters&.workflow_template.present?

        scope.sort_by_option(sort_order)
      end
    end
  end
end
