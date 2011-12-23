module SwissLib

  class Initialize

    require 'setup'

    def initialize(settings)
      load_settings settings
      load_subtasks @project_type
    end

    def initialize_project
      copy_project_template
      copy_mercurial_hooks
      update_eclipse_files
      custom_initialize
      commit_updates
      deploy_project

      return @project_path
    end

    private

    def load_subtasks(project_type)
      subtasks = File.join(project_type, 'initialize.rb')
      require subtasks
    end

    def copy_project_template
      FileUtils.makedirs @project_path unless File.exists? @project_path
      # TODO: Throw exception if we can't find a base project
      FileUtils.cp_r(File.join(@project_base_path, @project_type, '.'), @project_path)
    end

    def copy_mercurial_hooks
      hgrc_from = File.join(@hooks_path, "hgrc")
      hgrc_to   = File.join(@project_path, '.hg')

      FileUtils.cp_r(hgrc_from, hgrc_to)

      hooks_from = File.join(@hooks_path, "update_staging.sh")
      hooks_to   = File.join(@project_path, '.hg', 'hooks')

      FileUtils.makedirs hooks_to unless File.exists? hooks_to
      FileUtils.cp_r(hooks_from, hooks_to)
    end

    def update_eclipse_files
      file_names = ['.project', 'build.properties', '.externalToolBuilders/Project Builder.launch']

      file_names.each do |file_name|
        text = File.read(File.join(@project_path, file_name))
        text.gsub!(/WORDPRESS_PROJECT/, @project_name)
        text.gsub!(/@DATABASE_PREFIX@/, @db_prefix)
        text.gsub!(/@DATABASE_USERNAME@/, "username")
        text.gsub!(/@DATABASE_PASSWORD@/, "password")
        text.gsub!(/@HOST_LOCAL@/, "http://localhost")
        text.gsub!(/@HOST_STAGING@/, @staging_url)
        File.open(File.join(@project_path, file_name), "w") {|file| file.puts text}
      end
    end

    def commit_updates
      `cd #{@project_path} && hg commit -m "Checking in project-specific settings." -u "www-data"`
    end

    # TODO: Clean this up, this code is replicated in project_initializer_staging.rb
    def deploy_project
      # Copy project from repository to web server directory
      FileUtils.rm_rf "#{@web_path}/#{@project_name}"
      FileUtils.makedirs "#{@web_path}/#{@project_name}" unless File.exists? "#{@web_path}/#{@project_name}"
      FileUtils.cp_r(File.join(@project_path, 'src', '.'), "#{@web_path}/#{@project_name}")
    end
  end
end
