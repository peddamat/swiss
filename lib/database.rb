module SwissLib

  class Database

    require 'fileutils'
    require 'setup'

    def initialize(project_type, project_name, temp = false)
      initialize_project_vars(project_type, project_name)

      if temp == true
        @project_path = File.join(@tmp_path, project_name)
      end

      @MYSQL_BIN     = "#{@mysql_path}/mysql -u#{@db_root_user} --password=#{@db_root_pass}"
      @MYSQLDUMP_BIN = "#{@mysql_path}/mysqldump -u#{@db_root_user} --password=#{@db_root_pass}"
    end

    def initialize_database(hsh = {})
      project_path = hsh[:project_path] || @project_path
      project_name = hsh[:project_name] || @project_name

      scripts_prep(project_path, project_name, "", "")

      `#{@MYSQL_BIN} < #{project_path}/db/tmp/001_init_database.sql 2>/dev/null`
    end

    def reload_database(hsh = {})
      project_path = hsh[:project_path] || @project_path
      project_name = hsh[:project_name] || @project_name

      scripts_prep(project_path, project_name, "", "")

      `#{@MYSQL_BIN} < #{project_path}/db/tmp/002_reload_database.sql`
      `#{@MYSQL_BIN} #{@db_name} < #{project_path}/db/database.sql`
    end

    def dump_database(hsh = {})
      db_name      = hsh[:db_name] || @db_name
      project_path = hsh[:project_path] || @project_path

      `#{@MYSQLDUMP_BIN} #{db_name} > #{project_path}/db/database.sql`
    end

    def update_database(local_project_url, prod_project_url)
      scripts_prep(@project_path, @project_name, local_project_url, prod_project_url)

      `#{@MYSQL_BIN} #{@db_name} < #{File.join(@project_path, "db", "tmp", '003_update_hostname.sql')}`
    end

    def update_hostname(hsh = {})
      url_to       = hsh[:url_to]
      url_from     = hsh[:url_from]
      db_name      = hsh[:db_name] || @db_name
      project_path = hsh[:project_path] || @project_path

      # TODO: Perhaps we should move this script over to the plugin scripts folder...
      #       Is there any reason why we'd need to deploy this with the projects?
      `php #{project_path}/scripts/searchreplacedb2.php #{db_name},#{@db_root_user},#{@db_root_pass},#{url_from},#{url_to}`
    end

    def import_database(url_from)
      initialize_database
      reload_database

      # TODO: When importing a project, we should grep through the database.sql file
      #  and determine which rows need updating, instead of hardcoding just a few tables

      # TODO: We prolly should to the searches without the 'http://' to support other protocols

      # The default Wordpress siteurl is: http://localhost/wordpress
      # - Update it to point to: http://localhost/@project_name
      update_hostname :url_to => "http://localhost/#{@project_name}", :url_from => url_from
      update_database url_from, "http://localhost/#{@project_name}"

      # Dump the updated database to database.sql
      dump_database

      # Now, initialize the database for the staging server
      update_hostname :url_to => "#{@staging_url}/#{@project_name}", :url_from => "http://localhost/#{@project_name}"
      update_database "http://localhost/#{@project_name}", "#{@staging_url}/#{@project_name}"

      # Clean-up
      FileUtils.rm_rf "#{@project_path}/db/tmp"
    end

    private

    def scripts_prep(project_path, project_name, dev_host, staging_url)
      FileUtils.rm_rf "#{project_path}/db/tmp"
      Dir.mkdir "#{project_path}/db/tmp"

      Dir.glob(File.join(project_path, "db", "*.sql")).each do |f|
        FileUtils.copy(f, "#{project_path}/db/tmp")
      end

      # Update database scripts
      file_names = ['001_init_database.sql', '002_reload_database.sql', '003_update_hostname.sql']

      file_names.each do |file_name|
        file_path = File.join(project_path, "db", file_name)
        next unless File.exists?(file_path)

        text = File.read(file_path)
        text.gsub!(/@DATABASE@/, @db_prefix + project_name)
        text.gsub!(/@DATABASE_USERNAME@/, "username")
        text.gsub!(/@DATABASE_PASSWORD@/, "password")
        text.gsub!(/@HOST_LOCAL@/, dev_host)
        text.gsub!(/@HOST_STAGING@/, staging_url)
        File.open(File.join(project_path, "db", "tmp", file_name), "w") {|file| file.puts text}
      end
    end

    def scripts_clean
      FileUtils.rm_rf "#{@tmp_path}/#{@project_name}/db/tmp"
    end
  end
end
