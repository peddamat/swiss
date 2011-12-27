def load_settings(settings, temp = false)
    # We need a pointer back to the settings hash so we can pass it around (this stinks)
    @settings = settings

    # We've got a ton of Settings, so instead of setting each instance variable
    #  manually, let's iterate through the hash and set them.
    settings.each { |key, value|
        if key.include? "_path"
            value = File.expand_path value
        end
        instance_variable_set("@#{key}", value)
    }

    # if temp == true
    #     @project_name = @project_name + "_temp"
    # end

    @db_prefix          = @project_type.strip + "_"
    @db_name            = @db_prefix + @project_name

    mysql_path     = `which mysql`.chomp
    mysqldump_path = `which mysqldump`.chomp
    @mysql_bin     = "#{mysql_path} -u#{@db_root_user} --password=#{@db_root_pass} -h #{@db_host}"
    @mysqldump_bin = "#{mysqldump_path} --skip-comments --extended-insert --complete-insert --skip-comments -u#{@db_root_user} --password=#{@db_root_pass} -h #{@db_host}"

    # This is the path the new project will be written to:
    #  i.e. /var/hg/repos/wordpress/foobar_12312312
    @project_path       = File.join(@repository_path, @project_type, @project_name)
    @tmp_project_path   = File.join(@tmp_path, @project_name + "_temp")
end
