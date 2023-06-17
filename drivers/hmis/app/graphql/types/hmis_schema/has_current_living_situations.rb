###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCurrentLivingSituations
      extend ActiveSupport::Concern

      class_methods do
        def current_living_situations_field(name = :current_living_situations, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::CurrentLivingSituation.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            resolve_current_living_situations
          end
        end
      end

      def resolve_current_living_situations(scope = object.current_living_situations, **args)
        scoped_current_living_situations(scope, **args)
      end

      private

      def scoped_current_living_situations(scope)
        scope.viewable_by(current_user).order(information_date: :desc)
      end
    end
  end
end
