###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GroupedSelectTwoInput < SimpleForm::Inputs::GroupedCollectionSelectInput
  def input_html_classes
    super.push('stimulus-select')
  end

  def input(wrapper_options = nil)
    label_method, value_method = detect_collection_methods

    options = input_html_options
    options[:data] ||= {}
    options[:data]['stimulus-select-target'] ||= ''
    options[:data]['stimulus-select-target'] << ' element '

    merged_input_options = merge_wrapper_options(options, wrapper_options)
    @builder.grouped_collection_select(
      attribute_name,
      grouped_collection,
      group_method,
      group_label_method,
      value_method,
      label_method,
      input_options,
      merged_input_options,
    )
  end
end
