module DisableDoubleClickOnSimpleForms
  def submit(field, options = {})
    if field.is_a?(Hash)
      field[:data] ||= {}
      field[:data][:disable_with] ||= field[:value] || 'Please wait ...'
    else
      options[:data] ||= {}
      options[:data][:disable_with] ||= options[:value] || 'Please wait ...'
    end
    super(field, options)
  end
end

SimpleForm::FormBuilder.prepend(DisableDoubleClickOnSimpleForms)