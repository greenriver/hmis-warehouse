###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCeReferrals
      extend ActiveSupport::Concern

      include ::Hmis::Concerns::HmisArelHelper

      class_methods do
        def ce_referrals_field(name = :ce_referrals, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = { type: Types::HmisSchema::CeReferral.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            filters_argument HmisSchema::CeReferral, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      included do
        def resolve_ce_referrals(scope = object.ce_referrals, **args)
          scoped_ce_referrals(scope, **args)
        end
      end

      private

      def scoped_ce_referrals(scope, user: current_user, filters: nil)
        raise unless Hmis::Ce.configuration.enabled? # TODO(#7506) permissions

        scope = scope.viewable_by(user)

        scope = scope.where(status: filters&.status) if filters&.status.present?

        opportunity_table = Hmis::Ce::Opportunity.arel_table
        scope = scope.joins(:opportunity).where(opportunity_table[:project_id].in(filters&.project)) if filters.respond_to?(:project) && filters&.project.present?
        scope = scope.joins(opportunity: :project).where(p_t[:project_type].in(filters&.project_type)) if filters.respond_to?(:project_type) && filters&.project_type.present?
        scope = scope.joins(:opportunity).where(opportunity_table[:workflow_template_identifier].in(filters&.workflow_template)) if filters.respond_to?(:workflow_template) && filters&.workflow_template.present?

        if filters.respond_to?(:on_current_step_since) && filters&.on_current_step_since.present?
          step_table = Hmis::WorkflowExecution::Step.arel_table
          scope = scope.joins(:current_steps).where(step_table[:updated_at].lt(filters.on_current_step_since))
          # todo @martha how does this work with multiple steps? needs spec
        end

        scope.order(created_at: :desc, id: :asc)
      end
    end
  end
end
