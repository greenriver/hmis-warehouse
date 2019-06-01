###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class NumericInput < SimpleForm::Inputs::NumericInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly
      display_value = object.send(attribute_name)
      if has_hint?
        template.content_tag(:p, display_value, label_html_options)
      else
        template.content_tag(:p, display_value, label_html_options)
      end
    else
      super(wrapper_options)
    end
  end
end
