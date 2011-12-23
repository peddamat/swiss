module SwissLib

  class Initialize

    require 'fileutils'
    require 'date'
    require 'database'

    def custom_initialize
      update_wordpress_files
      load_wordpress_database
    end

    private

    # TODO: We also need to update the "Authentication Unique Keys and Salts."
    def update_wordpress_files
      file_names = ['wp-config.php']

      file_names.each do |file_name|
        text = File.read(File.join(@project_path, 'src', file_name))
        text.gsub! /(.*)'DB_NAME'.*'(.*)'(.*)/, '\1\'DB_NAME\', \'' + @db_prefix + @project_name + '\'\3'
        text.gsub! /(.*)'DB_USER'.*'(.*)'(.*)/, "\\1\'DB_USER\', \'username\'\\3"
        text.gsub! /(.*)'DB_PASSWORD'.*'(.*)'(.*)/, "\\1\'DB_PASSWORD\', \'password\'\\3"
        text.gsub! /(.*)'DB_HOST'.*'(.*)'(.*)/, "\\1'DB_HOST', 'localhost'\\3"
        File.open(File.join(@project_path, 'src', file_name), "w") {|file| file.puts text}
      end
    end

    def load_wordpress_database
      @settings['project_name'] = @project_name
      @settings['project_type'] = "wordpress"
      woo = SwissLib::Database.new @settings

      woo.import_database("http://localhost/wordpress")
    end
  end
end

