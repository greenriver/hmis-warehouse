###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# paper trail class for application-db records (users, groups, etc)
# Note, warehouse records have a different version table/model
module GrPaperTrail
  class Version < ActiveRecord::Base
    include ::GrPaperTrailVersionBehavior
  end
end
