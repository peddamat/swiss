module SwissLib

  class Export

    require 'fileutils'
    require 'setup'
    require 'database'

    require 'setup'

    def initialize(project_name, project_type, settings)
      project_tasks = File.join(project_type, 'export.rb')
      require project_tasks

      load_settings project_type, project_name
    end
  end
end
