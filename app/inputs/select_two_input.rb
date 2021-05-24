###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class SelectTwoInput < CollectionSelectInput
  def input_html_classes
    super.push('stimulus-select')
  end

  def input(wrapper_options = nil)
    label_method, value_method = detect_collection_methods

    data = {
      data: {
        target: 'stimulus-select.stimulusSelectElement',
        action: 'change->stimulus-select#sayHello',
      },
    }

    merged_input_options = merge_wrapper_options(input_html_options.deep_merge(data), wrapper_options)

    @builder.collection_select(
      attribute_name,
      collection,
      value_method,
      label_method,
      input_options,
      merged_input_options,
    )
  end
end
