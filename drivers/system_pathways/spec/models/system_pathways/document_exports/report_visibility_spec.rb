###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemPathways::DocumentExports::ReportExport, type: :model do
  let(:report_class) { SystemPathways::Report }
  let(:report_definition_url) { 'system_pathways/warehouse_reports/reports' }

  it_behaves_like 'a document export limited to visible reports'
end
