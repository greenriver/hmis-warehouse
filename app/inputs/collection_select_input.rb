###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CollectionSelectInput < SimpleForm::Inputs::CollectionSelectInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly || input_options[:readonly] == true
      # Rails.logger.info 'ELLIOT' << detect_collection_methods.inspect
      # Rails.logger.info 'ELLIOT' << collection.inspect
      # Rails.logger.info 'ELLIOT' << object.send(attribute_name).inspect
      label_method = detect_collection_methods.first
      value_method = detect_collection_methods.last
      selected_value = object.send(attribute_name)
      selected_object = collection.select { |m| m.send(value_method).to_s == selected_value.to_s }
      value = selected_object.map { |m| m.send(label_method) }.first
      # Rails.logger.info 'ELLIOT' << '----------'
      # Rails.logger.info 'ELLIOT' << selected_value.inspect
      # Rails.logger.info 'ELLIOT' << selected_object.inspect
      # Rails.logger.info 'ELLIOT' << selected_object.map{|m| m.send(label_method)}.inspect
      # Rails.logger.info 'ELLIOT' << '----------'

      template.label_tag(nil, value, label_html_options)
    else
      super(wrapper_options)
    end
  end
end
