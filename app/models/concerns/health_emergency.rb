###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HealthEmergency
  extend ActiveSupport::Concern
  included do
    acts_as_paranoid
    has_paper_trail

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :user
    belongs_to :agency
  end
end
