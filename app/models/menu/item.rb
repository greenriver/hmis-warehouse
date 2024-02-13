###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Menu::Item < OpenStruct
  # attr_accessor(
  #   :user,
  #   :parent,
  #   :children,
  #   :title,
  #   :path,
  #   :id,
  #   :icon,
  #   :target,
  #   :html_class,
  #   :visible, # lambda to determine if the user has access to this item
  #   :active, # true if the current path matches the item's path
  # )

  def add_child(item)
    self.children ||= {}
    children[item.path] = item
  end

  def to_html
    self_html = [[title, path]]
    return self_html unless children.present?

    self_html + children.map(&:to_html)
  end

  def children?
    children.present?
  end

  def icon?
    icon.present?
  end
end
