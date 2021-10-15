###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasCeData::GrdaWarehouse
  class CasReferralEvent < GrdaWarehouseBase
    self.table_name = 'cas_referral_events'

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: :hmis_client_id, optional: true
    has_many :program_to_projects, primary_key: :program_id, foreign_key: :program_id
    has_many :projects, through: :program_to_projects, class_name: 'GrdaWarehouse::Hud::Project'
  end
end
