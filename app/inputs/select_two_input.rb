class SelectTwoInput < CollectionSelectInput
  def input_html_options
    if options.dig(:input_html, :multiple)
      super.deep_merge(data: { 'close-on-select' => 'false' })
    else
      super
    end
  end

  def input_html_classes
    super + ['select2']
  end
end
