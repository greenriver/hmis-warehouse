###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class SelectTwoInput < CollectionSelectInput
  def input_html_classes
    super.push('stimulus-select')
  end

  def input(wrapper_options = nil)
    label_method, value_method = detect_collection_methods

    if @builder.options[:wrapper] == :readonly || input_options[:readonly] == true
      selected_values = object.send(attribute_name)
      Array.wrap(selected_values).each do |selected_value|
        selected_object = collection.detect { |m| m.send(value_method).to_s == selected_value.to_s }
        display_value = selected_object&.send(label_method)
        next unless display_value.present?

        existing_classes = label_html_options.try(:[], :class)
        existing_classes << 'd-block'

        if display_value.present?
          template.concat(template.content_tag(:p, display_value, label_html_options.merge(class: existing_classes)))
        else
          template.concat(template.content_tag(:em, 'Blank', label_html_options.merge(class: existing_classes)))
        end
      end
    else
      options = input_html_options
      options[:data] ||= {}
      options[:data]['stimulus-select-target'] ||= ''
      options[:data]['stimulus-select-target'] << ' element '
      merged_input_options = merge_wrapper_options(options, wrapper_options)

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
end
