require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionTen, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionTen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q10a: Gender of Adults' do
  end

  describe 'Q10b: Gender of Children' do
  end

  describe 'Q10c: Gender of Persons Missing Age Information' do
  end
end
