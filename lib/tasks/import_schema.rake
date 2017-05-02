namespace :import_schema do
  desc "Convert DB Schema file from XSD to migration"
  task :from_xsd => [:environment, "log:info_to_stdout"] do
    require 'nokogiri'
    schema_file = 'var/HUD_HMIS.xsd.xml'
    migration_file = 'tmp/hud_migration.rb'
    xml = Nokogiri::XML::Document.parse(File.read(schema_file))
    tables = xml.xpath('//xs:complextype').map do |m|
      columns = m.children.xpath('xs:element').map do |el|
        column = {
          name: el.attribute('name').to_s,
          specified_type: el.attribute('type').to_s,
          type: column_type(el.attribute('type').to_s),
        }
      end
      {name: m.attribute('name').to_s, columns: columns}
    end
    File.open(migration_file, 'w') { |file|
      tables.each do |t|
        if t[:columns].any?
          file.write "create_table :#{t[:name]} do |t|\n"
          t[:columns].each do |c|
            file.write "\tt.#{c[:type]}, '#{c[:name]}'\n"
          end
          file.write "end\n"
        end
      #   #puts t.inspect
      #   if t[:columns].any?
      #     t[:columns].each do |c|
      #       if c[:type].nil?
      #         puts c.inspect
      #       end
      #     end
      #   end
      end
    }
  end

  def column_type(c)
    case c
      when 'hmis:noYes', 'xs:unsignedInt', 'xs:nonNegativeInteger', 'xs:integer', /refused/i, /pathSMIInformation/i
        :integer
      when /^hmis:string/, /hashing/i, 'hmis:zipCode', 'hmis:vamcStation', 'hmis:cocCode', 'hmis:exportPeriodType', 'hmis:exportDirective', 'xs:string'
        :string
      when 'xs:dateTime'
        :datetime
      when 'xs:date'
        :date
      when 'hmis:dateRangeCapped'
        :daterange
      when 'hmis:money'
        :decimal
      else
        :integer
    end
  end
end