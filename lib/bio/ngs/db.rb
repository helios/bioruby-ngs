module Bio
  module Ngs
    class Db
      
      require 'active_support/inflector'
      
      attr_reader :connection
      
      def initialize(yaml_file="conf/database.yml",models_file=nil)
        @yaml_file = yaml_file
        @db = ActiveRecord::Base
        @db.establish_connection YAML.load_file(@yaml_file)
        # ONLY FOR DEBUG
        #require 'logger'
        #ActiveRecord::Base.logger = Logger.new 'log/db.log'
        require models_file if models_file
      end
    
      def create_tables(migrations_path)
        ActiveRecord::Migration.verbose = true
        ActiveRecord::Migrator.migrate(migrations_path,nil)
      end
      
      def export(table,fileout)
        klass = @db.const_get(table.singularize.camelize)
        columns = klass.column_names
        out = File.open(fileout,"w") 
        out.write columns.join("\t")+"\n"
        klass.find(:all).each do |output|
          records = output.attributes
          values = []
          columns.each {|c| values << records[c]}
          out.write values.join("\t")+"\n"
        end
      end
      
      def insert_many(table,query,values=[])
        klass = @db.const_get(table.singularize.camelize)
        klass.transaction do 
          values.each do |v|
            sql = @db.send(:sanitize_sql_array,[query]+v)
            @db.connection.execute(sql)
          end
        end
      end
      
    end
  end
end