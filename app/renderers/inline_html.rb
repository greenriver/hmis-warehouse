class InlineHtml < TranslatedHtml
  # Don't wrap with paragraph returns, we'll use this for short snippets only
  def paragraph(text)
    text
  end
end
