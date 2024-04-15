#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module HmisExternalApis
  module Hmis
    module Hud
      module CustomServiceExtension
        extend ActiveSupport::Concern

        included do
          has_one :warehouse_project, class_name: 'Hmis::Hud::Project', through: :project
        end
      end
    end
  end
end
