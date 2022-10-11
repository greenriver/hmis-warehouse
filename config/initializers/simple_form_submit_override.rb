# Rails.logger.debug "Running initializer in #{__FILE__}"

module DisableDoubleClickOnSimpleForms
  def submit(field, options = {})
    if field.is_a?(Hash)
      field[:data] ||= {}
      field[:data][:disable_with] ||= field[:value] || 'Please wait ...' unless options.dig(:data, :disable_with) == false
    else
      options[:data] ||= {}
      options[:data][:disable_with] ||= options[:value] || 'Please wait ...' unless options.dig(:data, :disable_with) == false
    end
    super(field, options)
  end
end

SimpleForm::FormBuilder.prepend(DisableDoubleClickOnSimpleForms)
