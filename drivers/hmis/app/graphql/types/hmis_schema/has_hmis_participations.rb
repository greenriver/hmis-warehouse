###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasHmisParticipations
      extend ActiveSupport::Concern

      class_methods do
        def hmis_participations_field(name = :hmis_participations, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::HmisParticipation.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            resolve_hmis_participations(object)
          end

          define_method(:resolve_hmis_participations) do |record|
            record.hmis_participations.
              viewable_by(current_user).
              order(hmis_participation_status_start_date: :desc)
          end
        end
      end
    end
  end
end
