require 'rails_helper'

RSpec.describe 'Date and Time Cleanup', type: :model do
  describe 'dates convert as expected' do
    dates = {
      '08-MAY-67' => '1967-05-08',
      '17-JUN-20' => '2020-06-17',
      '17-JUN-2020' => '2020-06-17',
      '1990-07-16' => '1990-07-16',
      '12-31-2015' => '2015-12-31',
      '2015-12-31' => '2015-12-31',
      '5/1/00' => '2000-05-01',
      '5/1/2000' => '2000-05-01',
      '12/11/99' => '1999-12-11',
      '12/11/1999' => '1999-12-11',
      '5-1-00' => '2000-05-01',
      '5-1-2000' => '2000-05-01',
      '12-11-99' => '1999-12-11',
      '12-11-1999' => '1999-12-11',
    }

    it 'returns expected dates' do
      aggregate_failures do
        dates.each do |source, dest|
          expect(HmisCsvTwentyTwenty::Importer::Client.fix_date_format(source)).to eq(dest)
        end
      end
    end
  end

  describe 'dates convert as expected' do
    times = {
      '08-MAY-67 21:39:00' => '1967-05-08 21:39:00',
      '17-JUN-20 21:39:00' => '2020-06-17 21:39:00',
      '17-JUN-2020 21:39:00' => '2020-06-17 21:39:00',
      '1990-07-16 21:39:00' => '1990-07-16 21:39:00',
      '12-31-2015 21:39:00' => '2015-12-31 21:39:00',
      '2015-12-31 21:39:00' => '2015-12-31 21:39:00',
      '5/1/00 21:39:00' => '2000-05-01 21:39:00',
      '5/1/2000 21:39:00' => '2000-05-01 21:39:00',
      '12/11/99 21:39:00' => '1999-12-11 21:39:00',
      '12/11/1999 21:39:00' => '1999-12-11 21:39:00',
      '5-1-00 21:39:00' => '2000-05-01 21:39:00',
      '5-1-2000 21:39:00' => '2000-05-01 21:39:00',
      '12-11-99 21:39:00' => '1999-12-11 21:39:00',
      '12-11-1999 21:39:00' => '1999-12-11 21:39:00',
    }
    it 'returns expected times' do
      aggregate_failures do
        times.each do |source, dest|
          expect(HmisCsvTwentyTwenty::Importer::Client.fix_time_format(source)).to eq(dest)
        end
      end
    end
  end
end
