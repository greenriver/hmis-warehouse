###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Sources::PaperTrailVersions < ::GraphQL::Dataloader::Source
  def initialize(item_type)
    @item_type = item_type
  end

  def fetch(item_ids)
    versions_by_item_id = GrdaWarehouse.paper_trail_versions.
      where.not(whodunnit: nil).
      where(item_type: @item_type, item_id: item_ids).
      order(:created_at, :id).
      select(:id, :event, :whodunnit, :item_id, :item_type, :user_id, :true_user_id). # select only fields we need for performance
      to_a.group_by(&:item_id)

    item_ids.map do |item_id|
      versions = versions_by_item_id[item_id] || []

      latest_version = versions.last # db-ordered so we choose the last record
      created_by_version = versions.detect { |e| e.event == 'create' }

      {
        last_user_id: version_user_id(latest_version),
        created_by_user_id: version_user_id(created_by_version),
      }
    end
  end

  protected

  def version_user_id(version)
    return nil unless version

    version.clean_true_user_id || version.clean_user_id
  end
end
