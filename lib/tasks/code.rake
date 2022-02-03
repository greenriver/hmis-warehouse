namespace :code do
  desc 'Ensure the copyright is included in all ruby files'
  task :maintain_copyright, [:environment, 'log:info_to_stdout'] do
    puts 'Adding license text in all .rb files that don\'t already have it'
    puts current_text
    @modified = 0
    files.each do |path|
      add_copyright_to_file(path)
    end

    puts "Modified #{@modified} #{'record'.pluralize(@modified)}"
  end

  def current_text
    <<~COPYRIGHT
      ###
      # Copyright 2016 - 2021 Green River Data Analysis, LLC
      #
      # License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
      ###

    COPYRIGHT
  end

  def files
    Dir.glob("#{Rails.root}/app/{**/}*.rb") + Dir.glob("#{Rails.root}/drivers/{**/}*.rb")
  end

  def add_copyright_to_file path
    puts ">>> Prepending copyright to #{path}"
    @modified += 1
    lines = File.open(path).readlines
    if lines.slice(0, current_text.lines.count).join == current_text
      puts 'Found existing copyright, ignoring'
      @modified -= 1
    else
      tempfile = Tempfile.new('with_copyright')
      line = ''
      tempfile.write(current_text)
      tempfile.write(line)
      tempfile.write(lines.join)
      tempfile.flush
      tempfile.close
      FileUtils.cp(tempfile.path, path)
    end
  end
end
