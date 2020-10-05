require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionFourteen, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionFourteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q14a: Domestic Violence History' do
  end

  describe 'Q14b: Persons Fleeing Domestic Violence' do
  end
end
