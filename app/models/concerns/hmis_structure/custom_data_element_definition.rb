###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisStructure::CustomDataElementDefinition
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :CustomDataElementDefinitionID
    acts_as_paranoid(column: :DateDeleted) unless included_modules.include?(Paranoia)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '2026', nil
        {
          CustomDataElementDefinitionID: {
            type: :string,
            limit: 32,
          },
          owner_type: {
            type: :string,
            null: false,
          },
          field_type: {
            type: :string,
            null: false,
          },
          key: {
            type: :string,
            null: false,
          },
          label: {
            type: :string,
          },
          repeats: {
            type: :boolean,
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
