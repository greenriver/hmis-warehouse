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
      label_method = detect_collection_methods.first
      value_method = detect_collection_methods.last
      selected_value = Array.wrap(object.send(attribute_name)).map(&:to_s)
      selected_objects = collection.map do |m|
        [m.send(value_method).to_s, m.send(label_method)]
      end.to_h.select { |k, _| k.in?(selected_value) }
      value = selected_objects.values.join(', ')
      existing_classes = label_html_options.try(:[], :class)
      existing_classes << 'd-block'
      existing_classes << 'readonly-value'
      if value.present?
        template.label_tag('p', value, label_html_options.merge(class: existing_classes))
      else
        template.content_tag(:em, 'Blank', label_html_options)
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
