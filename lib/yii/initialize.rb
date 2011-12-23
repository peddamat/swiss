module SwissLib

  class Initialize

    def custom
      update_yii_files
    end

    private

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
  end
end
