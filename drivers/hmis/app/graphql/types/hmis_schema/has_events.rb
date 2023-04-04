###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
          default_field_options = { type: HmisSchema::Event.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::EventSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_events_with_loader(association_name = :events, **args)
        load_ar_association(object, association_name, scope: scoped_events(Hmis::Hud::Event, **args))
      end

      def resolve_events(scope = object.events, **args)
        scoped_events(scope, **args)
      end

      private

      def scoped_events(scope, sort_order: :event_date)
        scope = scope.viewable_by(current_user)
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
