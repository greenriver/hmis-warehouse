###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::UserHmisDataSourceRole < ::ApplicationRecord
  self.table_name = :user_hmis_data_source_roles
  has_paper_trail(
    meta: {
      referenced_user_id: :referenced_user_id,
      referenced_entity_name: :referenced_entity_name,
    },
  )

  belongs_to :user
  belongs_to :role
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  def referenced_user_id
    user.id
  end

  def referenced_entity_name
    role.name
  end

  def self.describe_changes(version, _changes)
    if version.event == 'create'
      ["Added role #{version.referenced_entity_name}"]
    else
      ["Removed role #{version.referenced_entity_name}"]
    end
  end
end
