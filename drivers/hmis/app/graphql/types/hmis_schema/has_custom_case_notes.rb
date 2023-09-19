###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCustomCaseNotes
      extend ActiveSupport::Concern

      class_methods do
        def custom_case_notes_field(name = :custom_case_notes, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::CustomCaseNote.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            # argument :sort_order, Types::HmisSchema::CustomCaseNoteSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_custom_case_notes(scope = object.custom_case_notes, **args)
        scoped_custom_case_notes(scope, **args)
      end

      private

      def scoped_custom_case_notes(scope)
        scope.viewable_by(current_user).order(date_created: :desc).order(:id)
      end
    end
  end
end
