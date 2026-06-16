###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class InlineHtml < TranslatedHtml
  # Don't wrap with paragraph returns, we'll use this for short snippets only
  def paragraph(text)
    text
  end
end
