module SwissLib

  class Export

    require 'fileutils'
    require 'setup'
    require 'database'

    require 'setup'

    def initialize(settings)
      load_settings settings
      load_subtasks @project_type
    end

    private

    def load_subtasks(project_type)
      project_tasks = File.join(project_type, 'export.rb')
      require project_tasks
    end
  end
end
