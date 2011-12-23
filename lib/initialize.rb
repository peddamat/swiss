module SwissLib

  class Initialize

    require 'setup'

    def initialize(project_name, project_type, settings)
      project_tasks = File.join(project_type, 'initialize.rb')
      require project_tasks

      date = DateTime.now.strftime("%H%M%S")
      project_name = get_project_directory(project_name, date)

      setup project_type, project_name
    end

    def initialize_project(project_name, project_type)

      copy_project_template
      copy_mercurial_hooks
      update_eclipse_files
      custom
      commit_updates
      deploy_project

      return @project_path
    end

    private

    def copy_project_template
      FileUtils.makedirs(File.join(@project_path, @project_type)) unless File.exists?(File.join(@project_path, @project_type))
      FileUtils.cp_r(File.join(@project_base_path, @project_type, '.'), @project_path)
    end

    def copy_mercurial_hooks
      hgrc_path = File.join(@hooks_path, "hgrc")
      FileUtils.cp_r(hgrc_path, File.join(@project_path, '.hg'))

      hooks_path = File.join(@hooks_path, "update_staging.sh")
      hooks_dest = File.join(@project_path, '.hg', 'hooks')
      Dir.mkdir(hooks_dest)
      FileUtils.cp_r(hooks_path, hooks_dest)
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
      FileUtils.rm_rf "#{@web_dir}/#{@project_name}"
      FileUtils.cp_r(File.join(@project_path, 'src', '.'), "#{@web_dir}/#{@project_name}")
    end

    def get_project_directory(project_name, date)
      sprintf('%s_%s', project_name, date).strip.downcase.gsub(' ','_')
    end
  end
end
