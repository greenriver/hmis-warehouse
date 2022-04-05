###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern

    def name_of_whodunnit?
      return whodunnit unless whodunnit&.to_i&.to_s == whodunnit

      User.find_by(id: whodunnit)&.name
    end
  end
end
