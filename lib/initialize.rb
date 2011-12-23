module SwissLib

  class Initialize

    require 'fileutils'
    require 'date'
    require 'setup'
    require 'database'

    def initialize
    end

    def initialize_project(project_name, project_type)
      date = DateTime.now.strftime("%H%M%S")
      @project_name = get_project_directory(project_name, date)

      initialize_project_vars project_type, @project_name

      if project_type == "wordpress"
        initialize_wordpress_project
      elsif project_type == "yii"
        initialize_yii_project
      end

      return @project_path
    end

    private

    def initialize_yii_project
      copy_project_template "yii"
      copy_mercurial_hooks
      update_eclipse_files
      update_yii_files
      commit_updates
    end

    def initialize_wordpress_project
      copy_project_template "wordpress"
      copy_mercurial_hooks
      update_eclipse_files
      update_wordpress_files
      load_wordpress_database
      commit_updates

      deploy_project
    end

    def copy_project_template(type)
      FileUtils.makedirs(File.join(@project_path, type)) unless File.exists?(File.join(@project_path, type))
      FileUtils.cp_r(File.join(@project_base_path, type, '.'), @project_path)
    end

    def copy_mercurial_hooks
      hgrc_path = File.dirname(__FILE__) + "/../scripts/hooks/hgrc"
      FileUtils.cp_r(hgrc_path, File.join(@project_path, '.hg'))

      hooks_path = File.dirname(__FILE__) + "/../scripts/hooks/update_staging.sh"
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

    def update_yii_files
      file_names = ['main.php', 'console.php']

      file_names.each do |file_name|
        text = File.read(File.join(@project_path, 'src', 'webapp', 'protected', 'config', file_name))
        text.gsub!(/YII_PROJECT/, @project_name)
        text.gsub!(/MYSQL_USER/, "username")
        text.gsub!(/MYSQL_PASSWORD/, "password")
        File.open(File.join(@project_path, 'src', 'webapp', 'protected', 'config', file_name), "w") {|file| file.puts text}
      end
    end

    # TODO: We also need to update the "Authentication Unique Keys and Salts."
    def update_wordpress_files
      file_names = ['wp-config.php']

      file_names.each do |file_name|
        text = File.read(File.join(@project_path, 'src', file_name))
        text.gsub! /(.*)'DB_NAME'.*'(.*)'(.*)/, '\1\'DB_NAME\', \'' + @db_prefix + @project_name + '\'\3'
        text.gsub! /(.*)'DB_USER'.*'(.*)'(.*)/, "\\1\'DB_USER\', \'username\'\\3"
        text.gsub! /(.*)'DB_PASSWORD'.*'(.*)'(.*)/, "\\1\'DB_PASSWORD\', \'password\'\\3"
        text.gsub! /(.*)'DB_HOST'.*'(.*)'(.*)/, "\\1'DB_HOST', 'localhost'\\3"
        File.open(File.join(@project_path, 'src', file_name), "w") {|file| file.puts text}
      end
    end

    def commit_updates
      `cd #{@project_path} && hg commit -m "Checking in project-specific settings." -u "www-data"`
    end

    def load_wordpress_database
      woo = SwissLib::Database.new "wordpress", @project_name

      woo.import_database("http://localhost/wordpress")
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
