module SwissLib

  class Initialize

    require 'setup'

    def initialize(settings)
      load_settings settings
      load_subtasks @project_type
    end

    def initialize_project
      # make_project_directories
      copy_tooling_files
      copy_project_template
      copy_mercurial_hooks
      update_eclipse_files

      hook_initialize

      commit_updates
      deploy_project

      return @project_path
    end

    private

    def load_subtasks(project_type)
      subtasks = File.join(project_type, 'initialize.rb')
      require subtasks
    end

    def make_project_directories
      FileUtils.makedirs File.join(@project_path, 'src') unless File.exists? File.join(@project_path, 'src')
    end

    def copy_tooling_files
      `hg clone #{File.join(@base_path, 'tooling', 'eclipse')} -q #{@project_path}`
    end

    def copy_project_template
      begin
        FileUtils.cp_r(File.join(@project_base_path, @project_type, '.'), File.join(@project_path, 'src'))
      rescue
        print "Can't find project\n";
        exit 1
      end
    end

    def copy_mercurial_hooks
      hgrc_from = File.join(@hooks_path, "hgrc")
      hgrc_to   = File.join(@project_path, '.hg')

      FileUtils.makedirs hgrc_to unless File.exists? hgrc_to
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
      `cd #{@project_path} && hg add`
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
