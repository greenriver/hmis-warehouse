###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCustomDataElements
      extend ActiveSupport::Concern

      class_methods do
        def custom_data_elements_field(
          name = :custom_data_elements,
          description = nil,
          **override_options,
          &block
        )
          default_field_options = {
            type: [Types::HmisSchema::CustomDataElement],
            null: false,
            description: description,
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            resolve_custom_data_elements(object)
          end
        end
      end

      # Build GraphqlCdeValueAdapter instances for a record's custom data elements.
      #
      # calculated_cdeds: optional array of Hmis::Hud::CustomDataElementDefinition records with a
      # calculation_expression. These have no persisted CustomDataElement rows (values are derived at query
      # time via Dentaku). The caller is responsible for supplying the relevant set (pre-batched). For each
      # CDED in this list, a synthetic unpersisted CDE carrying the computed value is injected into the result.
      def resolve_custom_data_elements(record, calculated_cdeds: [])
        # cde_definitions comes from has_many :through :custom_data_elements, so it only includes CDEDs that
        # already have at least one persisted row. Calculated CDEDs (no stored rows) are passed in separately.
        cde_values = load_ar_association(record, :custom_data_elements).group_by(&:data_element_definition_id)
        cde_definitions = load_ar_association(record, :custom_data_element_definitions).sort_by(&:id)

        adapters = cde_definitions.uniq.map do |cded|
          Hmis::Hud::GraphqlCdeValueAdapter.new(
            definition: cded,
            custom_data_elements: cde_values[cded.id]&.sort_by(&:id) || [],
          )
        end

        return adapters if calculated_cdeds.empty?

        evaluator = Hmis::CalculatedField::Evaluator.new

        calculated_cdeds.each do |cded|
          result = evaluator.evaluate(cded, enrollment: record)
          # Evaluation yields nil when required resolvers are disabled or variables are unavailable
          next if result.nil?

          value_column = Hmis::Hud::CustomDataElementDefinition::FIELD_TYPE_TO_COLUMN[cded.field_type.to_sym]

          synthetic_cde = Hmis::Hud::CustomDataElement.new(
            owner: record,
            data_element_definition: cded,
            data_source_id: record.data_source_id,
            value_column => result,
          )

          # Unpersisted rows have no DB id; CustomDataElementValue requires a stable non-null id.
          # Use "#{cded.id}:synthetic" — deterministic and won't collide with real persisted CDE ids.
          stable_id = "#{cded.id}:synthetic"
          synthetic_cde.define_singleton_method(:id) { stable_id }

          adapters << Hmis::Hud::GraphqlCdeValueAdapter.new(
            definition: cded,
            custom_data_elements: [synthetic_cde],
          )
        end

        adapters
      end
    end
  end
end
