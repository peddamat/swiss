module SwissLib

	class Database
		def prep_for_dump(url_from, url_to)
			# TODO: When importing a project, we should grep through the database.sql file
			#  and determine which rows need updating, instead of hardcoding just a few tables

			# TODO: We prolly should to the searches without the 'http://' to support other protocols

			# The default Wordpress siteurl is: http://localhost/wordpress
			# - Update it to point to: http://localhost/@project_name
			update_hostname  :url_from => url_from, :url_to => url_to
		end

		def prep_for_staging(url_from, url_to)
			update_hostname  :url_from => url_from, :url_to => url_to
		end

		def update_hostname(hsh = {})
			url_to       = hsh[:url_to]
			url_from     = hsh[:url_from]
			db_name      = hsh[:db_name] || @db_name
			project_path = hsh[:project_path] || @project_path

			# TODO: Perhaps we should move this script over to the plugin scripts folder...
			#       Is there any reason why we'd need to deploy this with the projects?
			`php #{project_path}/scripts/searchreplacedb2.php #{db_name},#{@db_root_user},#{@db_root_pass},#{url_from},#{url_to}`
		end
	end
end
