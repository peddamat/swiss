def load_settings(settings)

    # We've got a ton of Settings, so instead of setting each instance variable
    #  manually, let's iterate through the hash and set them.  For a description
    #  of each variable, see init.rb.
    settings.each { |key, value|
        if key.include? "_path"
            value = File.expand_path value
        end
        instance_variable_set("@#{key}", value)
    }

    @settings = settings

    @mysql_path         = "/usr/bin"
    @db_prefix          = @project_type.strip + "_"
    @db_name            = @db_prefix + @project_name

    # This is the path the new project will be written to:
    #  i.e. /var/hg/repos/wordpress/foobar_12312312
    @project_path       = File.join(@repository_path, @project_type, @project_name)
    @TMP_PROJECT_PATH   = File.join(@tmp_path, @project_name + "_temp")
end
