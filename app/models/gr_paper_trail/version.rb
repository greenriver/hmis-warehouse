###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# paper trail class for application-db records (users, groups, etc)
# Note, warehouse records have a different version table/model
module GrPaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern
  end
end
