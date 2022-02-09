###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Cas
  class ProjectClient < CasBase
    belongs_to :client, class_name: 'Cas::Client', optional: true
    belongs_to :data_source, optional: true
  end
end
