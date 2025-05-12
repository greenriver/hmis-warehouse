FactoryBot.define do
  factory :gr_paper_trail_version, class: 'GrPaperTrail::Version' do
    item_type { 'User' }
    item_id { 1 }
    event { 'update' }
    object_changes do
      {
        'updated_at' => [1.day.ago, Time.current],
      }.to_yaml
    end
  end
end
