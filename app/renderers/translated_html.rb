###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class TranslatedHtml < Redcarpet::Render::HTML
  # NOTE: this will convert anything within {{ }} to a translated string
  def postprocess(html)
    html.gsub(/{{(.*?)}}/) { |_m| Translation.translate(Regexp.last_match(1)) }
  end
end
