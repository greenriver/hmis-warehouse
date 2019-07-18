###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class TranslatedHtml < Redcarpet::Render::HTML
  def postprocess(html)
    html.gsub(/{{(.+)}}/) { |m| _($1) }
  end
end