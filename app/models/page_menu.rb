###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PageMenu < OpenStruct
  # attr_accessor(:user, :items, :location)

  def add_item(menu_item)
    self.items ||= {}
    self.items[menu_item.path] = menu_item
  end

  def to_html
    items.map { |path, item| [path, item.to_html] }
  end
end
