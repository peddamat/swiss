module SwissLib

  class Staging

    require 'setup'
    require 'database'
    require 'fileutils'

    def initialize(settings)
      load_settings settings
      load_subtasks @project_type
    end

    def update_staging
      # Reload the database from the repository
      woo = SwissLib::Database.new @settings
      woo.reload_database

      hook_stage_project(woo)

      woo.update_database "http://localhost", @staging_url

      # Clean-up
      FileUtils.rm_rf "#{@project_path}/db/tmp"

      # Copy project from repository to web server directory
      FileUtils.rm_rf "#{@web_path}/#{@project_name}"
      FileUtils.cp_r(File.join(@project_path, 'src', '.'), "#{@web_path}/#{@project_name}")
    end

    private

    def load_subtasks(project_type)
      project_tasks = File.join(project_type, 'staging.rb')
      require project_tasks
    end
  end
end
