###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Menu::SiteMenu < OpenStruct
  def add_child(item)
    self.children ||= {}
    children[item.path] = item
  end
end
