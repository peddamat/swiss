def initialize_project_vars(project_type, project_name)
    # We've got a ton of Settings, so instead of setting each instance variable
    #  manually, let's iterate through the hash and set them.  For a description
    #  of each variable, see init.rb.

    # Setting is defined by the Redmine environment, if it's not defined, assume
    #  we're being called from the command-line script...
    if defined? Setting
        settings = Setting.plugin_redmine_project_initializer
        settings.each { |key, value| instance_variable_set("@#{key}", value) }
    else
        require 'rubygems'
        require 'json'

        file = File.open('config.json', 'r')
        json = file.readlines.to_s

        settings = JSON.parse(json)
        settings.each { |key, value| instance_variable_set("@#{key}", value)}
    end

    @mysql_path         = "/usr/bin"
    @db_prefix          = project_type.strip + "_"
    @db_name            = @db_prefix + project_name

    # This is the path the new project will be written to:
    #  i.e. /var/hg/repos/wordpress/foobar_12312312
    @project_name       = project_name
    @project_type       = project_type
    @project_path       = File.join(@repository_path, project_type, project_name)
    @TMP_PROJECT_PATH   = File.join(@tmp_path, project_name + "_temp")
end
