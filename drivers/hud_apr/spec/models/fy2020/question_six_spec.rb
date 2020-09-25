require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Shared::Fy2020::QuestionSix, type: :model do
  include_context 'apr context'

  before(:all) do
    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the fixpoint to regenerate
    setup(default_setup_path) unless Fixpoint.exists? :hud_hmis_export
    store_fixpoint_unless_present :hud_hmis_export
    restore_fixpoint :hud_hmis_export

    HudApr::Generators::Shared::Fy2020::QuestionSix.new(options: default_options).run!
  end

  after(:all) do
    cleanup
  end

  describe 'Q6a: Personally Identifiable Information' do
  end

  describe 'Q6b: Data Quality: Universal Data Elements' do
  end

  describe 'Q6c: Data Quality: Income and Housing Data Quality' do
  end

  describe 'Q6d: Data Quality: Chronic Homelessness' do
  end

  describe 'Q6e: Data Quality: Timeliness' do
  end

  describe 'Q6f: Data Quality: Inactive Records: Street Outreach and Emergency Shelter' do
  end
end

