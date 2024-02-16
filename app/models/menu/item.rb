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
    self.children ||= []
    # Only add the item if it will be visible
    return unless item.show?

    children << item
  end

  def options
    {
      href: href,
      target: target,
      subject: subject,
      data: data,
    }.reject { |_, v| v.nil? }
  end

  def href
    return path if subject.blank?

    "mailto:#{path}?subject=#{subject}"
  end

  def children?
    children.present?
  end

  def icon?
    icon.present?
  end

  def group?
    group.present?
  end

  def show?
    if visible.nil?
      return children.any?(&:show?) if children?

      false
    else
      visible.call(user)
    end
  end

  def target?
    target.present?
  end

  def data?
    data.present?
  end

  def children_paths(item, paths)
    found_paths = []

    return found_paths unless item.children?

    item.children.each do |child|
      found_paths += children_paths(child, paths)

      found_paths << child.path
    end

    found_paths
  end

  def collapsed_class(path_info)
    return :show if children_paths(self, paths)&.include?(path_info)

    :collapsed
  end
end
