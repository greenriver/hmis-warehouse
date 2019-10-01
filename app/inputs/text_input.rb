###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class TextInput < SimpleForm::Inputs::TextInput
  include ActionView::Helpers::TextHelper
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly
      formatted_value = object.send(attribute_name)
      template.content_tag(:div, simple_format(formatted_value), label_html_options)
    else
      super(wrapper_options)
    end
  end
end
