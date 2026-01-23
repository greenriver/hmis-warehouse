###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCeDefaultContacts
      extend ActiveSupport::Concern

      class_methods do
        def ce_default_contacts_field(name = :ce_default_contacts, description = 'Coordinated Entry default contacts grouped by swimlane', **override_options, &block)
          default_field_options = { type: [HmisSchema::CeDefaultContactsBySwimlane], null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end
        end
      end

      included do
        def resolve_ce_default_contacts(scope = Hmis::Ce::DefaultSwimlaneAssignment, **args)
          scoped_ce_default_contacts(scope, **args)
        end
      end

      private

      def scoped_ce_default_contacts(scope)
        return Hmis::Ce::DefaultSwimlaneAssignment.none unless Hmis::Ce.configuration.enabled?

        scope = scope.includes(:user, swimlane: :template).
          joins(:swimlane).
          order(Hmis::WorkflowDefinition::Swimlane.arel_table[:id])

        scope.group_by(&:swimlane).map do |swimlane, assignments|
          OpenStruct.new(
            swimlane: swimlane,
            contacts: assignments,
          )
        end
      end
    end
  end
end
