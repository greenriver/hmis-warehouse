namespace :code do
  # NOTE, you can check a PR for this with
  # git diff -U0 --minimal HEAD~1 | grep -v '^+#.*2023' | grep -v '^+#.*LICENSE.md' | grep -v '^+###$' | grep -v '^+#$' | grep -v '^diff --git' | grep -v '^index' | grep '^--- a' | grep '^+++ b' | more
  desc 'Ensure the copyright is included in all ruby files'
  task :maintain_copyright, [] => [:environment, 'log:info_to_stdout'] do
    puts 'Adding license text in all .rb files that don\'t already have it'
    puts ::Code.copywright_header
    @modified = 0
    files.each do |path|
      add_copyright_to_file(path)
    end

    puts "Modified #{@modified} #{'record'.pluralize(@modified)}"
  end

  # rails code:generate_hud_list_json\["2024","lib/data/CSV Specifications Machine-Readable_FY2024.xlsx"\]
  desc 'Generate HUD list json file'
  task :generate_hud_list_json, [:year, :csv_file_path] => [:environment, 'log:info_to_stdout'] do |_task, args|
    HudCodeGen.generate_hud_list_json(args.year.to_i, args.csv_file_path)
  end

  desc 'Generate HUD list mapping module'
  task generate_hud_lists: [:environment, 'log:info_to_stdout'] do
    filenames = []
    filenames << HudCodeGen.generate_hud_lists('2022')
    filenames << HudCodeGen.generate_hud_lists('2024')
    exec("bundle exec rubocop -A --format simple #{filenames.join(' ')} > /dev/null")
  end

  def files
    Dir.glob("#{Rails.root}/app/{**/}*.rb") + Dir.glob("#{Rails.root}/drivers/{**/}*.rb")
  end

  def add_copyright_to_file path
    puts ">>> Prepending copyright to #{path}"
    @modified += 1
    lines = File.open(path).readlines
    if lines.slice(0, ::Code.copywright_header.lines.count).join == ::Code.copywright_header
      puts 'Found existing copyright, ignoring'
      @modified -= 1
    else
      tempfile = Tempfile.new('with_copyright')
      line = ''
      tempfile.write(::Code.copywright_header)
      tempfile.write(line)
      tempfile.write(lines.join)
      tempfile.flush
      tempfile.close
      FileUtils.cp(tempfile.path, path)
    end
  end
end
