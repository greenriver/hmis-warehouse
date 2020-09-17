RSpec.shared_examples 'question seven' do
  describe 'Q7: Persons Served' do
    before(:all) do
      HudApr::Generators::Shared::Fy2020::QuestionSeven.new(options: default_options).run!
    end

    describe 'Q7a: Number of Persons Served' do
    end

    describe 'Q7b: Point-in-Time Count of Persons on the Last Wednesday' do
    end
  end
end
