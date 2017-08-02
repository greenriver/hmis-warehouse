FactoryGirl.define do
  factory :existing_export, class: 'GrdaWarehouse::Hud::Export' do
    ExportID '1234'
    ExportStartDate '2016-07-01'
    ExportEndDate '2017-08-01'
  end

  factory :new_export_same_id_different_start, class: 'GrdaWarehouse::Hud::Export' do
    ExportID '1234'
    ExportStartDate '2016-06-01'
    ExportEndDate '2017-08-01'
  end

  factory :new_export_same_id_later_end, class: 'GrdaWarehouse::Hud::Export' do
    ExportID '1234'
    ExportStartDate '2016-07-01'
    ExportEndDate '2017-09-01'
  end

  factory :new_export_same_id_earlier_end, class: 'GrdaWarehouse::Hud::Export' do
    ExportID '1234'
    ExportStartDate '2016-07-01'
    ExportEndDate '2017-05-01'
  end

  factory :new_export_different_id, class: 'GrdaWarehouse::Hud::Export' do
    ExportID '4321'
    ExportStartDate '2016-07-01'
    ExportEndDate '2017-05-01'
  end
end
