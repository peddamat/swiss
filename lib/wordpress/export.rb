module SwissLib

  class Export

    require 'fileutils'
    require 'setup'
    require 'database'

    def hook_export_project(new_host, new_mysql_db, new_mysql_user, new_mysql_pass, new_db_host)

      woo = SwissLib::Database.new(@settings)

      # Make sure they didn't forget the 'http://'
      new_host = "http://" + new_host unless new_host.starts_with? 'http://'

      # Create a temporary project directory
      if File.exists?(@tmp_project_path)
        FileUtils.rm_rf(@tmp_project_path)
      end
      Dir.mkdir(@tmp_project_path)

      # TODO: If we're cloning the directory, new plugins, etc... won't be copied!
      #       We should prolly commit before the clone to catch and changes on production.

      # Clone project trunk to temporary project directory
      `cd #{@project_path} && hg clone . #{@tmp_project_path} -q`

      # Save live database to db directory
      woo.dump_database

      # TODO: Commit the live database to the repo

      # Create temporary database
      @settings['project_name'] = "#{@project_name}_temp"
      woo = SwissLib::Database.new(@settings, true)
      woo.initialize_database
      woo.reload_database

      # Update hostnames with fancy search script
      # NOTE: The ordering of these replacements is important!
      #  The URLs need to be ordered from more-specific to less-specific
      woo.update_hostname :url_to => "#{new_host}", :url_from => "http://staging.talentgurus.net/#{@project_name}"
      woo.update_hostname :url_to => "#{new_host}", :url_from => "http://staging.talentgurus.net"
      woo.update_hostname :url_to => "#{new_host}", :url_from => "http://localhost/#{@project_name}"
      woo.update_hostname :url_to => "#{new_host}", :url_from => "http://localhost"

      # Update rest of hostnames
      woo.update_database "http://staging.talentgurus.net/#{@project_name}", new_host
      woo.update_database "http://staging.talentgurus.net", new_host
      woo.update_database "http://localhost/#{@project_name}", new_host
      woo.update_database "http://localhost", new_host

      # Save updated database
      woo.dump_database

      # Update wp-config.php
      text = File.read "#{@tmp_project_path}/src/wp-config.php"
      text.gsub! /(.*)'DB_NAME'.*'(.*)'(.*)/, '\1\'DB_NAME\', \'' + new_mysql_db + '\'\3'
      text.gsub! /(.*)'DB_USER'.*'(.*)'(.*)/, "\\1\'DB_USER\', \'#{new_mysql_user}\'\\3"
      text.gsub! /(.*)'DB_PASSWORD'.*'(.*)'(.*)/, "\\1\'DB_PASSWORD\', \'#{new_mysql_pass}\'\\3"
      text.gsub! /(.*)'DB_HOST'.*'(.*)'(.*)/, "\\1'DB_HOST', '#{new_db_host}'\\3"
      File.open("#{@tmp_project_path}/src/wp-config.php", "w") {|file| file.puts text}

      # Clean-up package directory...
      # scripts_clean

      timestamp = Time.now.strftime("%y%m%d_%H%M")

      # Create source and database zips
      Dir.mkdir(File.join(@tmp_project_path, "zips"))
      `cd #{@tmp_project_path}/src && zip -qr #{@tmp_project_path}/zips/#{@project_name}_#{timestamp}_package.zip .`
      `cd #{@tmp_project_path}/db  && zip -qr #{@tmp_project_path}/zips/#{@project_name}_#{timestamp}_db.zip database.sql`

      # Tag release
      `cd #{@project_path} && hg tag release-#{timestamp} -u www-data`

      return @tmp_project_path
    end
  end
end
