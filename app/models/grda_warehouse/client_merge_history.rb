###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ClientMergeHistory < GrdaWarehouseBase
    belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: :id, foreign_key: :merged_into, optional: true
    belongs_to :source_client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: :id, foreign_key: :merged_from, optional: true

    def current_destination source_id
      if source_id.blank?
        @previous_dest_id
      else
        @previous_dest_id = @dest_id
        @dest_id = self.class.where(merged_from: source_id).order(created_at: :desc).limit(1).pluck(:merged_into)&.first
        current_destination @dest_id
      end
    end

  end
end
