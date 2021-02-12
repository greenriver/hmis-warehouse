###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Date and Time Cleanup', type: :model do
  describe 'dates convert as expected' do
    dates = {
      'HI THERE' => nil,
      'Jan 1' => nil,
      'Feb' => nil,
      'Jan 2010' => nil,
      'Yesterday' => nil,
      '99-999-9999' => nil,
      '9-99-99' => nil,
      '2019-01-32' => nil,
      '01-XXX-50' => nil,
      # this is OK for now, ideally we wouldn't do this but strftime advances days if they overrun by a few
      '1900-02-29' => '1900-03-01',
      '31-FEB-16' => '2016-03-02',
      '2/30/50' => '1950-03-02',
      # valid dates
      '29-FEB-16' => '2016-02-29',
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
      '' => '',
    }

    it 'returns expected dates' do
      aggregate_failures do
        dates.each do |source, dest|
          # puts "#{source} #{dest}"
          expect(HmisCsvTwentyTwenty::Importer::Client.fix_date_format(source)).to eq(dest)
        end
      end
    end
  end

  it 'infers centuries correctly' do
    # at any point in 2020 in Time.zone any date string
    # in `21 means 2021 while a date in `22 means 1922
    aggregate_failures do
      [Time.zone.local(2020, 1, 1), Time.zone.local(2020, 12, 31)].each do |current_time|
        travel_to current_time do
          expect(HmisCsvTwentyTwenty::Importer::Client.fix_date_format('1-JAN-20')).to eq('2020-01-01')
          expect(HmisCsvTwentyTwenty::Importer::Client.fix_date_format('31-DEC-20')).to eq('2020-12-31')
          expect(HmisCsvTwentyTwenty::Importer::Client.fix_date_format('1-JAN-21')).to eq('2021-01-01')
          expect(HmisCsvTwentyTwenty::Importer::Client.fix_date_format('31-DEC-21')).to eq('2021-12-31')
          expect(HmisCsvTwentyTwenty::Importer::Client.fix_date_format('1-JAN-22')).to eq('1922-01-01')
          expect(HmisCsvTwentyTwenty::Importer::Client.fix_date_format('31-DEC-22')).to eq('1922-12-31')
        end
      end
    end
  end

  private def old_fix_time_format(string)
    return unless string
    # Ruby handles yyyy-m-d just fine, so we'll allow that even though it doesn't match the spec
    return string if /\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:?\d{0,2}?/.match?(string)

    # Sometimes dates come in mm-dd-yyyy and Ruby Date really doesn't like that.
    if /\d{1,2}-\d{1,2}-\d{4}/.match?(string)
      month, day, year = string.split('-')
      return "#{year}-#{month}-#{day}"
    # Sometimes times come in mm/dd/yyyy hh:mm
    elsif %r{\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{1,2}:?\d{0,2}?}.match?(string)
      date, time = string.split(' ')
      month, day, year = date.split('/')
      return "#{year}-#{month}-#{day} #{time}"
    end
    # NOTE: by default ruby converts 2 digit years between 00 and 68 by adding 2000, 69-99 by adding 1900.
    # https://pubs.opengroup.org/onlinepubs/009695399/functions/strptime.html
    # Since we're almost always dealing with dates that are in the past
    # If the year is between 00 and next year, we'll add 2000,
    # otherwise, we'll add 1900
    @next_year ||= Date.current.next_year.strftime('%y').to_i
    d = DateTime.parse(string, false) # false to not guess at century
    if d.year <= @next_year
      d = d.next_year(2000)
    else
      d = d.next_year(1900)
    end
    d.strftime('%Y-%m-%d %H%M%S')
  end

  # describe 'performance' do
  #   it 'is reasonable fast' do
  #     n = 10_000
  #     puts "running #{n} iterations of old and new methods"
  #     res = Benchmark.bm(20) do |x|
  #       {
  #         easy: '2020-06-17 21:39',
  #         hard: '17-JUN-20 21:39'
  #       }.each do |label, string|
  #         x.report("new #{label} #{string}")  do
  #           n.times { HmisCsvTwentyTwenty::Importer::Client.fix_time_format(string) }
  #         end
  #         x.report("old #{label} #{string}")  do
  #           n.times { old_fix_time_format(string) }
  #         end
  #       end
  #     end
  #   end
  # end

  describe 'dates convert as expected' do
    time_with_zone = Time.current

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
      '08-MAY-67 21:39:05' => '1967-05-08 21:39:05',
      '17-JUN-20 21:39:05' => '2020-06-17 21:39:05',
      '17-JUN-2020 21:39:05' => '2020-06-17 21:39:05',
      '1990-07-16 21:39:05' => '1990-07-16 21:39:05',
      '12-31-2015 21:39:05' => '2015-12-31 21:39:05',
      '2015-12-31 21:39:05' => '2015-12-31 21:39:05',
      '5/1/00 21:39:05' => '2000-05-01 21:39:05',
      '5/1/2000 21:39:05' => '2000-05-01 21:39:05',
      '12/11/99 21:39:05' => '1999-12-11 21:39:05',
      '12/11/1999 21:39:05' => '1999-12-11 21:39:05',
      '5-1-00 21:39:05' => '2000-05-01 21:39:05',
      '5-1-2000 21:39:05' => '2000-05-01 21:39:05',
      '12-11-99 21:39:05' => '1999-12-11 21:39:05',
      '12-11-1999 21:39:05' => '1999-12-11 21:39:05',
      '08-MAY-67 21:39' => '1967-05-08 21:39:00',
      '17-JUN-20 21:39' => '2020-06-17 21:39:00',
      '17-JUN-2020 21:39' => '2020-06-17 21:39:00',
      '1990-07-16 21:39' => '1990-07-16 21:39:00',
      '12-31-2015 21:39' => '2015-12-31 21:39:00',
      '2015-12-31 21:39' => '2015-12-31 21:39:00',
      '5/1/00 21:39' => '2000-05-01 21:39:00',
      '5/1/2000 21:39' => '2000-05-01 21:39:00',
      '12/11/99 21:39' => '1999-12-11 21:39:00',
      '12/11/1999 21:39' => '1999-12-11 21:39:00',
      '5-1-00 21:39' => '2000-05-01 21:39:00',
      '5-1-2000 21:39' => '2000-05-01 21:39:00',
      '12-11-99 21:39' => '1999-12-11 21:39:00',
      '12-11-1999 21:39' => '1999-12-11 21:39:00',
      '08-MAY-67 4:39' => '1967-05-08 04:39:00',
      '17-JUN-20 4:39' => '2020-06-17 04:39:00',
      '17-JUN-2020 4:39' => '2020-06-17 04:39:00',
      '1990-07-16 4:39' => '1990-07-16 04:39:00',
      '12-31-2015 4:39' => '2015-12-31 04:39:00',
      '2015-12-31 4:39' => '2015-12-31 04:39:00',
      '5/1/00 4:39' => '2000-05-01 04:39:00',
      '5/1/2000 4:39' => '2000-05-01 04:39:00',
      '12/11/99 4:39' => '1999-12-11 04:39:00',
      '12/11/1999 4:39' => '1999-12-11 04:39:00',
      '5-1-00 4:39' => '2000-05-01 04:39:00',
      '5-1-2000 4:39' => '2000-05-01 04:39:00',
      '12-11-99 4:39' => '1999-12-11 04:39:00',
      '12-11-1999 4:39' => '1999-12-11 04:39:00',
      '' => '',
      time_with_zone => time_with_zone,
    }
    it 'returns expected times' do
      aggregate_failures do
        times.each do |source, dest|
          if source.blank? || source.acts_like?(:time)
            assert_equal dest, source
          else
            fixed = HmisCsvTwentyTwenty::Importer::Client.fix_time_format(source)
            assert_equal dest, fixed.strftime('%Y-%m-%d %H:%M:%S')
          end
        end
      end
    end
  end
end
