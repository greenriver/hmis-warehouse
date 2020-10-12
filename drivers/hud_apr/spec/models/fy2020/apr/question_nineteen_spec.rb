require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionNineteen, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionNineteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q19a1: Client Cash Income Change - Income Source - by Start and Latest Status' do
  end

  describe 'Q19a2: Client Cash Income Change - Income Source - by Start and Exit' do
  end

  describe 'Q19b: Disabling Conditions and Income for Adults at Exit' do
  end
end
