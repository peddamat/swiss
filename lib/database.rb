module SwissLib

  class Database

    require 'fileutils'
    require 'setup'

    def initialize(project_type, project_name, temp = false)
      load_subtasks project_type
      load_settings project_type, project_name

      if temp == true
        @project_path = File.join(@tmp_path, project_name)
      end

      @MYSQL_BIN     = "#{@mysql_path}/mysql -u#{@db_root_user} --password=#{@db_root_pass} -h #{@db_host}"
      @MYSQLDUMP_BIN = "#{@mysql_path}/mysqldump --skip-comments --extended-insert --complete-insert --skip-comments -u#{@db_root_user} --password=#{@db_root_pass} -h #{@db_host}"
    end

    def import_database(url_from)
      initialize_database
      reload_database

      prep_for_dump   url_from, "http://localhost/#{@project_name}"
      update_database url_from, "http://localhost/#{@project_name}"

      # Dump the updated database to database.sql
      dump_database

      # Now, initialize the database for the staging server
      prep_for_staging "http://localhost/#{@project_name}", "#{@staging_url}/#{@project_name}"
      update_database  "http://localhost/#{@project_name}", "#{@staging_url}/#{@project_name}"

      # Clean-up
      FileUtils.rm_rf "#{@project_path}/db/tmp"
    end

    def initialize_database(hsh = {})
      project_path = hsh[:project_path] || @project_path
      project_name = hsh[:project_name] || @project_name

      scripts_prep(project_path, project_name, "", "")

      print "* Initializing database...\n" unless @verbose.nil?
      `#{@MYSQL_BIN} < #{project_path}/db/tmp/001_init_database.sql 2>/dev/null`
    end

    def reload_database(hsh = {})
      project_path = hsh[:project_path] || @project_path
      project_name = hsh[:project_name] || @project_name

      scripts_prep(project_path, project_name, "", "")

      print "* Reloading database...\n" unless @verbose.nil?
      `#{@MYSQL_BIN} < #{project_path}/db/tmp/002_reload_database.sql`
      `#{@MYSQL_BIN} #{@db_name} < #{project_path}/db/database.sql`
    end

    def dump_database(hsh = {})
      db_name      = hsh[:db_name] || @db_name
      project_path = hsh[:project_path] || @project_path

      print "* Dumping database to database.sql...\n" unless @verbose.nil?
      `#{@MYSQLDUMP_BIN} #{db_name} > #{project_path}/db/database.sql`
    end

    def update_database(local_project_url, prod_project_url)
      scripts_prep(@project_path, @project_name, local_project_url, prod_project_url)

      print "* Updating hostnames:\n" unless @verbose.nil?
      print "* - #{local_project_url} -> #{prod_project_url}\n" unless @verbose.nil?
      `#{@MYSQL_BIN} #{@db_name} < #{File.join(@project_path, "db", "tmp", '003_update_hostname.sql')}`
    end

    private

    def load_subtasks(project_type)
      subtasks = File.join(project_type, 'database.rb')
      require subtasks
    end

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
