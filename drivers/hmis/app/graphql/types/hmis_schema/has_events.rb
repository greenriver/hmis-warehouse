###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasEvents
      extend ActiveSupport::Concern

      class_methods do
        def events_field(name = :events, description = nil, **override_options, &block)
          default_field_options = { type: [Types::HmisSchema::Event], null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::EventSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_events_with_loader(association_name = :events, **args)
        load_ar_association(object, association_name, scope: apply_event_arguments(Hmis::Hud::Event, **args))
      end

      def resolve_events(scope = object.events, **args)
        apply_event_arguments(scope, **args)
      end

      private

      def apply_event_arguments(scope, sort_order: :event_date)
        scope.sort_by_option(sort_order) if sort_order.present?
      end
    end
  end
end
