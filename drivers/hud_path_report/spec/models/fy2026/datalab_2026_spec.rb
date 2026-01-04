###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#
# @see docs/features/datalab-testkit.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../datalab_testkit/spec/models/datalab_testkit_context'
require_relative 'datalab_path/path_organization_p'
require_relative 'datalab_path/path_organization_v'
require_relative 'datalab_path/path_organization_x'

RSpec.describe 'PATH Datalab 2026', type: :model do
  include_context 'datalab testkit context'
  def project_type_filter(project_type)
    project_ids = GrdaWarehouse::Hud::Project.where(ProjectType: project_type).pluck(:id)
    project_ids_filter(project_ids)
  end

  def project_ids_filter(project_ids)
    ::Filters::HudFilterBase.new(shared_filter_spec.merge(project_ids: Array.wrap(project_ids)))
  end

  def run(generator, filter)
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: generator.questions.keys)).run!(email: false)
  end

  before(:all) do
    setup
  end

  if File.exist?('drivers/datalab_testkit/spec/fixtures/inputs/merged/source/Export.csv')
    include_context 'path organization p'
    include_context 'path organization v'
    include_context 'path organization x'
  else
    it 'Data Lab Testkit based tests are skipped, files are missing' do
      expect(true).to be false
    end
  end

  after(:all) do
    cleanup
  end
end
