module SwissLib

  class Initialize

    require 'fileutils'
    require 'date'
    require 'database'

    def hook_initialize
      copy_wpconfig
      copy_initial_database
      update_wordpress_files
      load_wordpress_database
    end

    private

    def copy_wpconfig
      FileUtils.copy File.join(@project_path, 'src', 'wp-config-sample.php'), File.join(@project_path, 'src', 'wp-config.php')
    end

    def copy_initial_database
      FileUtils.copy File.join(@base_path, 'db', 'wordpress', 'database.sql'), File.join(@project_path, 'db', 'database.sql')
    end

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

    # Load the initial database, which is installed, by default, to
    #  http://localhost/wordpress
    def load_wordpress_database
      woo = SwissLib::Database.new @settings
      woo.import_database("http://localhost/wordpress")
    end
  end
end

