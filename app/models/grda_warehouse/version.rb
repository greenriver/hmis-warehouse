###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Version < GrdaWarehouseBase
    include PaperTrail::VersionConcern
    include GrPaperTrailConcern

    belongs_to :hmis_client, class_name: 'Hmis::Hud::Client', foreign_key: :client_id, optional: true
    belongs_to :hmis_project, class_name: 'Hmis::Hud::Project', foreign_key: :project_id, optional: true

    def clean_true_user_id
      # If impersonating (i.e. user != true_user), use true_user_id
      result = user_id != true_user_id ? true_user_id : nil
      result || super
    end
  end
end
