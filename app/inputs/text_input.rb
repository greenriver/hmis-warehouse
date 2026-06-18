###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class TextInput < SimpleForm::Inputs::TextInput
  include ActionView::Helpers::TextHelper
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly || input_options[:readonly] == true
      formatted_value = object.send(attribute_name)
      if formatted_value.present?
        template.content_tag(:div, simple_format(formatted_value), label_html_options)
      else
        template.content_tag(:em, 'Blank', label_html_options)
      end
    else
      super(wrapper_options)
    end
  end
end
