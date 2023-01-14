###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../../datalab_testkit/spec/models/datalab_testkit_context'
require_relative 'datalab_apr/psh_coc_1'
require_relative 'datalab_apr/rrh_coc_1'
require_relative 'datalab_apr/rrh_coc_2'
require_relative 'datalab_apr/sso_coc'
require_relative 'datalab_apr/th'
require_relative 'datalab_caper/es_ee_esg'
require_relative 'datalab_caper/es_nbn_esg'
require_relative 'datalab_caper/hp_esg'
require_relative 'datalab_caper/rrh_esg'
require_relative 'datalab_caper/so_esg'
require_relative 'datalab_ce_apr/ce_only'

RSpec.describe 'Datalab 2023', type: :model do
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

  # Only run the tests if the source files are available
  if File.exist?('drivers/datalab_testkit/spec/fixtures/inputs/merged/source/Export.csv')
    include_context 'datalab psh coc 1 apr' # done
    include_context 'datalab rrh coc 1 apr' # done
    include_context 'datalab rrh coc 2 apr' # done
    include_context 'datalab sso coc apr' # done
    include_context 'datalab th coc apr'

    # include_context 'datalab es ee esg caper'
    # include_context 'datalab es nbn esg caper'
    # include_context 'datalab hp esg caper'
    # include_context 'datalab rrh esg caper'
    # include_context 'datalab so esg caper'

    # include_context 'datalab th ce ce apr' # done
  else
    xit 'Data Lab Testkit based tests are skipped, files are missing' do
    end
  end

  after(:all) do
    cleanup
  end
end
