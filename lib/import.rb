module SwissLib

  class Import

    require 'fileutils'

    def import_project_from_zip(project_name, zip_file, update_wpconfig = "true")

      initialize_project_vars("wordpress", project_name)

      @filebase = File.basename(zip_file, ".zip")

      # Extract zip file to a temporary directory
      `unzip -f -qq #{zip_file} -d #{File.join(@tmp_path, @filebase)}/`

      # Cleanup
      # File.delete(zip_file)

      # Search for the wp-config.php in the extracted zip file
      path = File.join(@tmp_path, @filebase, '**', 'wp-config.php')
      file = Dir.glob(path)[0]

      # TODO: IF WP-CONFIG NOT FOUND THROW EXCEPTION!

      if !file.nil?
        # Assume the wp-config.php is in the root of the Wordpress install
        base = File.dirname(file)

        # Copy the files directly into project repo
        FileUtils.cp_r(File.join(base, '.'), File.join(@project_path, 'src'))
      end

      # Search for database.sql in extracted zip file
      path = File.join(@tmp_path, @filebase, '**', 'database.sql')
      file = Dir.glob(path)[0]

      # TODO: IF DATABASE.SQL NOT FOUND THROW EXCEPTION!

      # Copy database.sql to 'db' directory
      FileUtils.cp_r(file, File.join(@project_path, 'db'))

      # Read siteurl from database.sql
      siteurl = ""
      dbfile = File.join(@project_path, 'db', "database.sql")
      File.open(dbfile) do |io|
       io.each { |line|
         # line.chomp!;
         matches = line.scan(/.*"siteurl","(.*)",.*/);
         # siteurl = matches[0] if !matches[0].nil?
         if !matches[0].nil?
          siteurl = matches[0]
        end
       }
      end

      # TODO: IF SITEURLs NOT FOUND THROW EXCEPTION!

      siteurl = siteurl[0]

      # Import production database
      woo = ProjectInitializer::Database.new "wordpress", project_name
      woo.import_database(siteurl)

      # Update wp-config.php
      if update_wpconfig == "true"
        text = File.read "#{@project_path}/src/wp-config.php"
        text.gsub! /(.*)'DB_NAME'.*'(.*)'(.*)/, '\1\'DB_NAME\', \'' + @db_name + '\'\3'
        text.gsub! /(.*)'DB_USER'.*'(.*)'(.*)/, "\\1\'DB_USER\', \'username\'\\3"
        text.gsub! /(.*)'DB_PASSWORD'.*'(.*)'(.*)/, "\\1\'DB_PASSWORD\', \'password\'\\3"
        text.gsub! /(.*)'DB_HOST'.*'(.*)'(.*)/, "\\1'DB_HOST', 'localhost'\\3"
        File.open("#{@project_path}/src/wp-config.php", "w") {|file| file.puts text}
      end

      deploy_project project_name
      commit_updates siteurl
    end

    # TODO: Clean this up, this code is replicated in project_initializer_staging.rb
    def deploy_project(project_name)
      # Copy project from repository to web server directory
      FileUtils.rm_rf "#{@web_dir}/#{project_name}"
      FileUtils.cp_r(File.join(@project_path, 'src', '.'), "#{@web_dir}/#{project_name}")
    end

    # TODO: Clean this up, this code is replicated in project_initializer_initialize.rb
    def commit_updates(siteurl)
      # puts `cd #{@project_path} && hg commit -m "Imported site from #{@siteurl}" -u "www-data"`
      puts `cd #{@project_path} && hg add && hg commit -m "Imported site from #{siteurl}" -u "www-data"`
    end
  end
end
