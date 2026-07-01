###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :hmis do
  desc "delete all rows from every model in the GrdaWarehouse::Hmis module"
  task :clean => [:environment] do
    GrdaWarehouse::Hmis::Base.descendants.reject(&:abstract_class?).each do |table|
      table.delete_all
    end
  end
end
