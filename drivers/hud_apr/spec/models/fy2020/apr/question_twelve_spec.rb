require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionTwelve, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionTwelve::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q12a: Race' do
  end

  describe 'Q12b: Ethnicity' do
  end
end
