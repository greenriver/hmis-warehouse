###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisStructure::CustomDataElement
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :CustomDataElementID
    acts_as_paranoid(column: :DateDeleted) unless included_modules.include?(Paranoia)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '2026', nil
        {
          CustomDataElementID: {
            type: :string,
            limit: 32,
          },
          CustomDataElementDefinitionID: {
            type: :string,
            limit: 32,
          },
          owner_type: {
            type: :string,
            null: false,
          },
          owner_id: {
            type: :integer,
            null: false,
          },
          value_float: {
            type: :float,
          },
          value_integer: {
            type: :integer,
          },
          value_boolean: {
            type: :boolean,
          },
          value_string: {
            type: :string,
          },
          value_text: {
            type: :string,
          },
          value_date: {
            type: :date,
          },
          value_json: {
            type: :jsonb,
          },
          DataCollectionStage: {
            type: :integer,
          },
          InformationDate: {
            type: :date,
          },
          DateCreated: {
            type: :datetime,
            null: false,
          },
          DateUpdated: {
            type: :datetime,
            null: false,
          },
          UserID: {
            type: :string,
            limit: 32,
            null: false,
          },
          DateDeleted: {
            type: :datetime,
          },
          ExportID: {
            type: :string,
            limit: 32,
          },
        }
      end
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {}
    end
  end
end
