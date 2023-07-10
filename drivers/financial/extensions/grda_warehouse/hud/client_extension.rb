###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      has_many :financial_clients, class_name: 'Financial::Client', inverse_of: :client
      has_many :transactions, through: :financial_clients
    end
  end
end
