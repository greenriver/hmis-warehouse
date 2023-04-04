###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class Client < CasBase
    self.table_name = :clients
    has_one :project_client, primary_key: :id, foreign_key: :client_id
    has_many :client_opportunity_matches
  end
end
