###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::DefinitionValidator

  def self.perform(...)
    new.perform(...)
  end

  # @param [Hash] document is a form definition document {'item' => [{...}] }
  # @param [Hash] valid_pick_lists validate that pick list references are in this set
  def perform(document, valid_pick_lists: [])
    @issues = []
    all_ids = check_ids(document, valid_pick_lists.to_set)
    check_references(document, all_ids)
    # we have cyclic dependencies and they seem to be supported by the front-end
    # check_cycles(dependencies)
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
    link_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        link_id = child_item['link_id']

        if child_item.key?('bounds')
          child_item['bounds'].map { |h| h['question'] }.compact.each do |reference|
            add_issue("Invalid link ID reference: #{reference} in 'bounds' prop of #{link_id}") unless all_ids.include?(reference)
          end
        end

        if child_item.key?('enable_when')
          child_item['enable_when'].flat_map{ |h| h.values_at('question', 'compare_question') }.compact.each do |reference|
            add_issue("Invalid link ID reference: #{reference} in 'enable_when' prop of #{link_id}") unless all_ids.include?(reference)
          end
        end

        if child_item.key?('autofill_values')
          child_item['autofill_values'].map { |h| h.values_at('value_question', 'sum_questions') }.flatten.compact.each do |reference|
            add_issue("Invalid link ID reference: #{reference} in 'autofill_values' prop of #{link_id}") unless all_ids.include?(reference)
          end
        end

        link_check.call(child_item)
      end
    end
    link_check.call(document)
  end
end
