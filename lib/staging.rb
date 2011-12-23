module SwissLib

  class Staging

    require 'fileutils'
    require 'setup'
    require 'database'

    def initialize(project_name, project_type="wordpress")
      initialize_project_vars(project_type, project_name)
    end

    def update_staging
      # Reload the database from the repository
      woo = SwissLib::Database.new @project_type, @project_name
      woo.reload_database

      # Update hostnames
      if @project_type =~ /wordpress/
        woo.update_hostname :url_to => @staging_url, :url_from => "http://localhost"
      end

      woo.update_database "http://localhost", @staging_url

      # Clean-up
      FileUtils.rm_rf "#{@project_path}/db/tmp"

      # Copy project from repository to web server directory
      FileUtils.rm_rf "#{@web_path}/#{@project_name}"
      FileUtils.cp_r(File.join(@project_path, 'src', '.'), "#{@web_path}/#{@project_name}")
    end

    def update_staging_from(project_path)
      @project_path = project_path
      update_staging
    end
  end
end
