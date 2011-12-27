module SwissLib

  class Import

    require 'fileutils'

    def initialize(settings)
      load_settings settings
      load_subtasks @project_type
    end

    def import_project_from_zip(zip_file, update_wpconfig = "true")

      @filebase = File.basename(zip_file, ".zip")

      # Extract zip file to a temporary directory
      `unzip -u #{zip_file} -d #{File.join(@tmp_path, @filebase)}/`

      # Cleanup
      # File.delete(zip_file)

      siteurl = hook_import_project update_wpconfig

      deploy_project @project_name
      commit_updates siteurl
    end

    # TODO: Clean this up, this code is replicated in project_initializer_staging.rb
    def deploy_project(project_name)
      # Copy project from repository to web server directory
      FileUtils.rm_rf "#{@web_path}/#{project_name}"
      FileUtils.cp_r(File.join(@project_path, 'src', '.'), "#{@web_path}/#{project_name}")
    end

    # TODO: Clean this up, this code is replicated in project_initializer_initialize.rb
    def commit_updates(siteurl)
      # puts `cd #{@project_path} && hg commit -m "Imported site from #{@siteurl}" -u "www-data"`
      puts `cd #{@project_path} && hg add && hg commit -m "Imported site from #{siteurl}" -u "www-data"`
    end

    private

    def load_subtasks(project_type)
      subtasks = File.join(project_type, 'import.rb')
      require subtasks
    end
  end
end
