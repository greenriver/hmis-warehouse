###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Sources
  # Batches form-definition loads for a set of form definition identifiers,
  # returning a { cded_key => { code => label } } map per identifier.
  # Enables resolving pick-list (CHOICE) custom data elements to their human-readable labels
  # without repeating the same form-definition SQL query for each CDED.
  class CdePickListMetadataByIdentifier < GraphQL::Dataloader::Source
    def initialize(data_source_id, user)
      @data_source_id = data_source_id
      @user = user
    end

    def fetch(identifiers)
      versions_by_identifier = Hmis::Form::Definition.
        where(identifier: identifiers, data_source_id: @data_source_id).
        published_or_retired.
        order(version: :desc, id: :desc).
        group_by(&:identifier)

      labels_by_identifier = versions_by_identifier.transform_values do |versions|
        merged_metadata = Hmis::Form::Definition.merge_pick_list_metadata(versions)

        merged_metadata.each_with_object({}) do |(key, metadata), labels_by_key|
          labels = Hmis::Hud::CustomDataElementDefinition.pick_list_labels_from_metadata(metadata, user: @user)
          labels_by_key[key] = labels if labels.present?
        end
      end

      identifiers.map { |identifier| labels_by_identifier[identifier] || {} }
    end
  end
end
