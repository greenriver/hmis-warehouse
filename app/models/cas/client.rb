###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Cas
  class Client < CasBase
    has_one :project_client, primary_key: :id, foreign_key: :client_id
    has_many :client_opportunity_matches
  end
end
