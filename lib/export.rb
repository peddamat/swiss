module SwissLib

  class Export

    require 'fileutils'
    require 'setup'
    require 'database'

    def export_wordpress_project(project_name, new_host, new_mysql_db, new_mysql_user, new_mysql_pass, new_db_host)

      initialize_project_vars("wordpress", project_name)
      woo = ProjectInitializer::Database.new("wordpress", project_name)

      # Make sure they didn't forget the 'http://'
      new_host = "http://" + new_host unless new_host.starts_with? 'http://'

      # Create a temporary project directory
      if File.exists?(@TMP_PROJECT_PATH)
        FileUtils.rm_rf(@TMP_PROJECT_PATH)
      end
      Dir.mkdir(@TMP_PROJECT_PATH)

      # Clone project trunk to temporary project directory
      `cd #{@project_path} && hg clone . #{@TMP_PROJECT_PATH} -q`

      # TODO: REMOVE THIS AFTER YOU FIX THE PUSH TO STAGING BUG
      # woo.initialize_database @TMP_PROJECT_PATH, "#{project_name}"
      # woo.reload_database @TMP_PROJECT_PATH, "#{project_name}"

      # Save live database to db directory
      woo.dump_database

      # Create temporary database
      woo = ProjectInitializer::Database.new("wordpress", "#{project_name}_temp", true)
      woo.initialize_database
      woo.reload_database

      # Update hostnames with fancy search script
      # NOTE: The ordering of these replacements is important!
      #  The URLs need to be ordered from more-specific to less-specific
      woo.update_hostname :url_to => "#{new_host}", :url_from => "http://staging.talentgurus.net/#{project_name}"
      woo.update_hostname :url_to => "#{new_host}", :url_from => "http://staging.talentgurus.net"
      woo.update_hostname :url_to => "#{new_host}", :url_from => "http://localhost/#{project_name}"
      woo.update_hostname :url_to => "#{new_host}", :url_from => "http://localhost"

      # Update rest of hostnames
      woo.update_database "http://staging.talentgurus.net/#{project_name}", new_host
      woo.update_database "http://staging.talentgurus.net", new_host
      woo.update_database "http://localhost/#{project_name}", new_host
      woo.update_database "http://localhost", new_host

      # Save updated database
      woo.dump_database

      # Update wp-config.php
      text = File.read "#{@TMP_PROJECT_PATH}/src/wp-config.php"
      text.gsub! /(.*)'DB_NAME'.*'(.*)'(.*)/, '\1\'DB_NAME\', \'' + new_mysql_db + '\'\3'
      text.gsub! /(.*)'DB_USER'.*'(.*)'(.*)/, "\\1\'DB_USER\', \'#{new_mysql_user}\'\\3"
      text.gsub! /(.*)'DB_PASSWORD'.*'(.*)'(.*)/, "\\1\'DB_PASSWORD\', \'#{new_mysql_pass}\'\\3"
      text.gsub! /(.*)'DB_HOST'.*'(.*)'(.*)/, "\\1'DB_HOST', '#{new_db_host}'\\3"
      File.open("#{@TMP_PROJECT_PATH}/src/wp-config.php", "w") {|file| file.puts text}

      # Clean-up package directory...
      # scripts_clean

      timestamp = Time.now.strftime("%y%m%d_%H%M")

      # Create source and database zips
      Dir.mkdir(File.join(@TMP_PROJECT_PATH, "zips"))
      `cd #{@TMP_PROJECT_PATH}/src && zip -qr #{@TMP_PROJECT_PATH}/zips/#{project_name}_#{timestamp}_package.zip .`
      `cd #{@TMP_PROJECT_PATH}/db  && zip -qr #{@TMP_PROJECT_PATH}/zips/#{project_name}_#{timestamp}_db.zip database.sql`

      # Tag release
      `cd #{@project_path} && hg tag release-#{timestamp} -u www-data`

      return @TMP_PROJECT_PATH
    end
  end
end
