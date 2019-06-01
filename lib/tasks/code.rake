namespace :code do
  desc "Ensure the copyright is included in all ruby files"
  task :update_copyright, [:environment, "log:info_to_stdout"] do |task, args|

    if previous_text == current_text
      puts 'Adding license text in all .rb files that don\'t already have it'
      puts current_text
      @modified = 0
      files.each do |path|
        add_copyright_to_file(path)
      end
    else
      puts 'Updating license text in all .rb files'
      puts 'changing from:'
      puts previous_text
      puts 'changing to:'
      puts current_text
    end
    puts "Modified #{@modified} #{'record'.pluralize()}"

  end

  def previous_text
    <<~COPYRIGHT
      ###
      # Copyright 2016 - 2019 Green River Data Analysis, LLC
      #
      # License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
      ###

    COPYRIGHT
  end

  # This can be updated when replacing an old version
  def current_text
    previous_text
  end

  def files
    Dir.glob("#{Rails.root}/app/{**/}*.rb")
  end

  def add_copyright_to_file path
    puts ">>> Prepending copyright to #{path}"
    @modified += 1
    lines =File.open(path).readlines
    if lines.slice(0,previous_text.lines.count).join == previous_text
      puts 'Found existing copyright, ignoring'
      @modified -= 1
    else
      tempfile = Tempfile.new('with_copyright')
      line=''
      tempfile.write(current_text)
      tempfile.write(line)
      tempfile.write(lines.join)
      tempfile.flush
      tempfile.close
      FileUtils.cp(tempfile.path,path)
    end
  end
end