require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionFifteen, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionFifteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q15: Living Situation' do
  end
end
