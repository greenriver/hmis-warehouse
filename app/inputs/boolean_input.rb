###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class BooleanInput < SimpleForm::Inputs::BooleanInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly
      display_value = object.send(attribute_name)
      template.content_tag(:span, display_value ? '✓' : '', label_html_options)
    else
      super(wrapper_options)
    end
  end
end
