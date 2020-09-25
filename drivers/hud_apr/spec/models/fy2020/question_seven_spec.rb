require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionSeven, type: :model do
  include_context 'apr context'

  before(:all) do
    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the fixpoint to regenerate
    setup(default_setup_path) unless Fixpoint.exists? :hud_hmis_export
    store_fixpoint_unless_present :hud_hmis_export
    restore_fixpoint :hud_hmis_export

    HudApr::Generators::Apr::Fy2020::QuestionSeven.new(options: default_options).run!
  end

  after(:all) do
    cleanup
  end

  describe 'Q7a: Number of Persons Served' do
  end

  describe 'Q7b: Point-in-Time Count of Persons on the Last Wednesday' do
  end
end
