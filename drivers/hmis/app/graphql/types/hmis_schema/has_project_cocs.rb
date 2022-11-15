###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasProjectCocs
      extend ActiveSupport::Concern

      class_methods do
        def project_cocs_field(name = :project_cocs, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::ProjectCoc.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_project_cocs_with_loader(association_name = :project_cocs, **args)
        load_ar_association(object, association_name, scope: scoped(Hmis::Hud::ProjectCoc, **args))
      end

      def resolve_project_cocs(scope = object.project_cocs, **args)
        apply_project_cocs_arguments(scope, **args)
      end

      def apply_project_cocs_arguments(scope)
        scope
      end
    end
  end
end
