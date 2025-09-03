###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../datalab_testkit/spec/models/datalab_testkit_context'
require_relative 'datalab_apr/multiple_projects'
require_relative 'datalab_apr/organization_i_psh'
require_relative 'datalab_apr/organization_m_rrh'
require_relative 'datalab_apr/organization_s_rrh'
require_relative 'datalab_apr/organization_y_sso'

require_relative 'datalab_caper/organization_f_so'
require_relative 'datalab_caper/organization_g_rrh'
require_relative 'datalab_caper/organization_s_th'
require_relative 'datalab_caper/organization_t_es'
require_relative 'datalab_caper/organization_t_hp'
require_relative 'datalab_caper/organization_v_es'

require_relative 'datalab_ce_apr/systemwide'

RSpec.describe 'Datalab 2026', type: :model do
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
    # include_context 'datalab multiple projects apr' # No Test Kit data files for "Organization X - RRH"
    include_context 'datalab organization i psh apr'
    # include_context 'datalab organization m rrh apr'
    # include_context 'datalab organization s rrh apr'
    # include_context 'datalab organization y sso apr'

    # # include_context 'datalab organization f so caper' # Looks like data issues with this organization - likely missing clients/enrollments
    # include_context 'datalab organization g rrh caper'
    # include_context 'datalab organization s th caper'
    # # include_context 'datalab organization t es caper' # Looks like data issues with this organization - likely missing clients/enrollments
    # include_context 'datalab organization t hp caper'
    # include_context 'datalab organization v es caper'

    # include_context 'datalab systemwide ce apr' # Looks like data issues - likely missing clients/enrollments
  else
    it 'Data Lab Testkit based tests are skipped, files are missing' do
      expect(true).to be false
    end
  end

  after(:all) do
    cleanup
  end
end
