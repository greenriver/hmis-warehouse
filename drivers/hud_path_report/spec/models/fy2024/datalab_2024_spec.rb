###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../datalab_testkit/spec/models/datalab_testkit_context'
require_relative 'datalab_path/path_organization_f'
require_relative 'datalab_path/path_organization_r'
require_relative 'datalab_path/path_organization_q'
require_relative 'active_storage_tests'

RSpec.describe 'PATH Datalab 2024', type: :model do
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
    include_context 'path organization f'
    include_context 'path organization q'
    include_context 'path organization r'
    include_context 'active storage tests hud path report'
  else
    it 'Data Lab Testkit based tests are skipped, files are missing' do
      expect(true).to be false
    end
  end

  after(:all) do
    cleanup
  end
end
