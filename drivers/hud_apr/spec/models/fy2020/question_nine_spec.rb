require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Shared::Fy2020::QuestionNine, type: :model do
  include_context 'apr context'

  before(:all) do
    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the fixpoint to regenerate
    setup(default_setup_path) unless Fixpoint.exists? :hud_hmis_export
    store_fixpoint_unless_present :hud_hmis_export
    restore_fixpoint :hud_hmis_export

    options = default_options.merge(night_by_night_shelter)
    HudApr::Generators::Shared::Fy2020::QuestionNine.new(options: options).run!
  end

  after(:all) do
    cleanup
  end

  describe 'Q9a: Number of Persons Contacted' do
  end

  describe 'Q9b: Number of Persons Engaged' do
  end
end
