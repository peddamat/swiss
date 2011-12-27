module SwissLib

  class Staging

    require 'setup'

    def hook_stage_project(database)
        # Update hostnames
        database.update_hostname :url_to => @staging_url, :url_from => "http://localhost"
    end
  end
end
