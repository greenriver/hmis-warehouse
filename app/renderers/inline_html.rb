###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class InlineHtml < TranslatedHtml
  # Don't wrap with paragraph returns, we'll use this for short snippets only
  def paragraph(text)
    text
  end
end
