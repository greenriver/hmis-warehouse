###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/ce-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCeParticipations
      extend ActiveSupport::Concern

      class_methods do
        def ce_participations_field(name = :ce_participations, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::CeParticipation.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            resolve_ce_participations(object)
          end

          define_method(:resolve_ce_participations) do |record|
            record.ce_participations.viewable_by(current_user)
          end
        end
      end
    end
  end
end
