namespace :code do
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

  desc 'Generate HUD list mapping module'
  task generate_hud_lists: [:environment, 'log:info_to_stdout'] do
    source = File.read('lib/data/hud_lists.json')
    skipped = []
    filename = 'lib/util/hud_lists.rb'

    map_lookup = {}
    arr = []
    arr.push ::Code.copywright_header
    arr.push "# frozen_string_literal: true\n"
    arr.push "# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY\n"
    arr.push 'module HudLists'
    arr.push '  module_function'
    JSON.parse(source).each do |element|
      next if skipped.include?(element['code'].to_s)

      function_name = "#{element['name'].underscore}_map"
      fn_already_defined = map_lookup.values.include?(function_name)
      map_lookup[element['code']] = function_name
      next if fn_already_defined

      map_values = element['values'].map do |obj|
        description = obj['description'].strip
        "#{obj['key'].to_json} => \"#{description}\""
      end.join(",\n")

      arr.push "def #{function_name}"
      arr.push "  {\n#{map_values}\n}.freeze"
      arr.push 'end'
    end

    map_contents = map_lookup.sort.to_h.map { |code, func| "#{code.to_json}: :#{func}" }.join(",\n")
    arr.push 'def hud_code_to_function_map'
    arr.push "  {\n#{map_contents}\n}.freeze"
    arr.push 'end'
    arr.push 'end'
    contents = arr.join("\n")
    File.open(filename, 'w') do |f|
      f.write(contents)
    end
    exec("bundle exec rubocop -A --format simple #{filename}")
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
