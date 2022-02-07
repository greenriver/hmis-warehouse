###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class NumericInput < SimpleForm::Inputs::NumericInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly || input_options[:readonly] == true
      display_value = object.send(attribute_name)
      template.content_tag(:p, display_value, label_html_options)
    else
      super(wrapper_options)
    end
  end
end
