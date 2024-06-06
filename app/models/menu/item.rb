###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Menu::Item < OpenStruct
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

  def collapse_regex
    # Most of the time we want an exact match, but for some sections there are a bunch of different paths for the drill-down
    terminator = match_pattern_terminator || '\z'
    regex = children_paths(self, paths).reject(&:blank?).map { |p| "^#{p}#{terminator}" }.join('|')
    regex << match_pattern if match_pattern.present?
    Regexp.new(regex)
  end

  def collapsed_class(path_info)
    return :show if always_open
    return :show if collapse_regex.match?(path_info.gsub("\n", '').slice(0, 500))

    :collapsed
  end
end
