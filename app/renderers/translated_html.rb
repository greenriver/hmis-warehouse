###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class TranslatedHtml < Redcarpet::Render::HTML
  # NOTE: this will convert anything within {{ }} to a translated string
  def postprocess(html)
    html.gsub(/{{(.*?)}}/) { |m| _($1) }
  end
end