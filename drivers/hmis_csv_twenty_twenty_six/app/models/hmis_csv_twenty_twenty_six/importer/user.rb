###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Importer
  class User < GrdaWarehouse::Hud::Base
    include ::HmisStructure::User
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2026_users'

    has_one :destination_record, **hud_assoc(:UserID, 'User')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      warehouse_class.importable.where(data_source_id: data_source_id)
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::User
    end

    # Don't ever mark these for deletion
    def self.prevent_import_deletions?
      true
    end

    def self.hmis_validations
      {
        UserID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
      }
    end
  end
end
