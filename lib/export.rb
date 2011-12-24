module SwissLib

  class Export

    require 'setup'
    require 'database'

    def initialize(settings)
      load_settings settings
      load_subtasks @project_type
    end

    def export_project(new_host, new_mysql_db, new_mysql_user, new_mysql_pass, new_db_host)
      hook_export_project(new_host, new_mysql_db, new_mysql_user, new_mysql_pass, new_db_host)
    end

    private

    def load_subtasks(project_type)
      project_tasks = File.join(project_type, 'export.rb')
      require project_tasks
    end
  end
end
