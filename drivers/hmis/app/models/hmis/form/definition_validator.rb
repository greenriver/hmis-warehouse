###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::DefinitionValidator

  def self.perform(...)
    new.perform(...)
  end

  def perform(document, valid_pick_lists: [])
    @issues = []
    all_ids = check_ids(document, valid_pick_lists)
    dependencies = check_references(document, all_ids)
    check_cycles(dependencies)
    @issues
  end

  protected

  def add_issue(msg)
    @issues.push(msg)
  end

  def check_ids(document,  valid_pick_lists)
    seen_link_ids = Set.new

    recur_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        link_id = child_item['link_id']
        add_issue("Missing link ID: #{child_item}") unless link_id.present?
        add_issue("Duplicate link ID: #{link_id}") if seen_link_ids.include?(link_id)

        seen_link_ids.add(link_id)

        # Ensure pick list reference is valid
        add_issue("Invalid pick list for Link ID #{link_id}: #{child_item['pick_list_reference']}") if child_item['pick_list_reference'] && valid_pick_lists.exclude?(child_item['pick_list_reference'])

        recur_check.call(child_item)
      end
    end
    recur_check.call(document)
    seen_link_ids
  end

  def check_references(document, all_ids)
    dep_map = {}
    link_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        link_id = child_item['link_id']
        references = []
        references += child_item.fetch('bounds', []).map{ |h| h['question']}
        references.compact.each do |reference|
          add_issue("Invalid link ID reference: #{reference} in #{link_id}") unless all_ids.include?(reference)
          dep_map[reference] ||= []
          dep_map[reference].push(link_id)
        end

        link_check.call(child_item)
      end
    end
    link_check.call(document)
    dep_map
  end

  # detect cycles in the dependencies
  #   has_cycles({ 'x1' => ['x2'], 'x2' => ['x3'], 'x3' => ['x1']})
  def check_cycles(dependencies)
    visited = Set.new
    stack = Set.new

    cyclic = lambda do |node|
      return false if !dependencies.key?(node) || dependencies[node].empty?
      return true if stack.include?(node)
      return false if visited.include?(node)

      visited.add(node)
      stack.add(node)

      result = dependencies[node].any? { |dependent| cyclic.call(dependent) }

      stack.delete(node)
      result
    end

    dependencies.each_key do |node|
      add_issue("cyclic dependency in : #{node}") if cyclic.call(node)
    end
  end
end
