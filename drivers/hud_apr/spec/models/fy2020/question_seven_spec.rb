require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionSeven, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionSeven::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q7a: Number of Persons Served' do
  end

  describe 'Q7b: Point-in-Time Count of Persons on the Last Wednesday' do
  end
end
