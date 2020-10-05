require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionSix, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionSix::QUESTION_NUMBER)
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
