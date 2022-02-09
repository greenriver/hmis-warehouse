###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PdfExportTemplateBase < ActionView::Base
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  attr_accessor :current_user
end
