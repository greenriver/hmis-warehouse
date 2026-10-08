###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectPassFail::DocumentExports::ProjectPassFailExport, type: :model do
  let(:report_class) { ProjectPassFail::ProjectPassFail }
  let(:report_definition_url) { report_class.url }

  it_behaves_like 'a document export limited to visible reports'
end
