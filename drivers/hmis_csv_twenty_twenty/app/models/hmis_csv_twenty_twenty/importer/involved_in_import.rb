###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class InvolvedInImport < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    self.table_name = 'involved_in_imports'
    # NOTE: record_actions: 'added', 'updated', 'unchanged', 'removed'

    belongs_to :importer_log
    belongs_to :record, polymorphic: true

    def self.actions
      [
        :added,
        :updated,
        :unchanged,
        :removed,
      ].freeze
    end

    def self.changed_personal_ids(importer_log_id)
      where(
        record_type: 'GrdaWarehouse::Hud::Client',
        record_action: :updated,
        importer_log_id: importer_log_id,
      ).pluck(:hud_key)
    end
  end
end
