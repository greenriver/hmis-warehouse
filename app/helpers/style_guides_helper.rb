###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module StyleGuidesHelper
  def detail_block title:, value:, wrapper_classes: []
    base_class = "c-detail"
    title_el = tag.div(title, class: "#{base_class}__title")
    value_el = tag.div(value, class: "#{base_class}__value")
    tag.div title_el + value_el, class: [ base_class ] + wrapper_classes.map{ |c| "#{base_class}--#{c}" }
  end

  def calendar_details_title_attr(metadata)
    return "" unless metadata
    sanitize(metadata.to_a.join(': ').to_s)
  end
end
