###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasGender
      extend ActiveSupport::Concern

      class_methods do
        def gender_field(name = :gender, description = nil, client_association: nil, **override_options, &block)
          default_field_options = {
            type: [Types::HmisSchema::Enums::Gender],
            null: false,
            description: description,
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            resolve_gender
          end

          define_method(:resolve_gender) do
            client = client_association ? object.send(client_association) : object

            selected_genders = ::HudUtility.gender_field_name_to_id.except(:GenderNone).select { |f| client.send(f).to_i == 1 }.values
            selected_genders << client.GenderNone if client.GenderNone && selected_genders.empty?
            selected_genders
          end
        end
      end
    end
  end
end
