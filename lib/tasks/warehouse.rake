task spec: ["db:test:prepare:warehouse"]

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :warehouse do
  namespace :db do |ns|
    namespace :schema do
      desc "Conditionally load the database schema"
      task :conditional_load, [] => [:environment] do |t, args|
        if GrdaWarehouseBase.connection.tables.length < 2
          Rake::Task['db:schema:load:warehouse'].invoke
        else
          puts "Refusing to load the warehouse database schema since there are tables present. This is not an error."
        end
      end
    end

    namespace :structure do
      desc "Conditionally load the database structure"
      task :conditional_load, [] => [:environment] do |t, args|
        if GrdaWarehouseBase.connection.tables.length == 0
          GrdaWarehouseBase.connection.execute(File.read('db/warehouse/structure.sql'))
        else
          puts "Refusing to load the warehouse database structure since there are tables present. This is not an error."
        end
      end
    end
  end
end
