###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class TranslatedHtml < Redcarpet::Render::HTML
  # NOTE: this will convert anything within {{ }} to a translated string
  def postprocess(html)
    html.gsub(/{{(.*?)}}/) { |_m| Translation.translate(Regexp.last_match(1)) }
  end
end
