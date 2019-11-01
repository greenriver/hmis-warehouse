###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Cas
  class ProjectClient < CasBase
    belongs_to :client, class_name: Cas::Client.name, optional: true
    belongs_to :data_source, optional: true
    belongs_to :primary_race, optional: true, primary_key: :numeric, foreign_key: :primary_race

  end
end