require 'yaml'

class WhiskeyDisk
  class Config
    class << self
      def environment_name
        return false unless (ENV['to'] && ENV['to'] != '')
        return ENV['to'] unless ENV['to'] =~ /:/
        ENV['to'].split(/:/)[1]
      end

      def specified_project_name
        return false unless (ENV['to'] && ENV['to'] =~ /:/)
        ENV['to'].split(/:/).first
      end

      def path
        (ENV['path'] && ENV['path'] != '') ? ENV['path'] : false
      end

      def check_staleness?
        !!(ENV['check'] && ENV['check'] =~ /^(?:t(?:rue)?|y(?:es)?|1)$/)
      end

      def contains_rakefile?(path)
        File.exists?(File.expand_path(File.join(path, 'Rakefile')))
      end

      def find_rakefile_from_current_path
        original_path = Dir.pwd
        while (!contains_rakefile?(Dir.pwd))
          return File.join(original_path, 'config') if Dir.pwd == '/'
          Dir.chdir('..')
        end
        File.join(Dir.pwd, 'config')
      ensure
        Dir.chdir(original_path)
      end

      def base_path
        return path if path
        find_rakefile_from_current_path
      end

      def configuration_file
        return path if path and File.file?(path)

        files = []

        files += [
          File.join(base_path, 'deploy', specified_project_name, "#{environment_name}.yml"),  # /deploy/foo/staging.yml
          File.join(base_path, 'deploy', "#{specified_project_name}.yml") # /deploy/foo.yml
        ] if specified_project_name

        files += [
          File.join(base_path, 'deploy', "#{environment_name}.yml"),  # /deploy/staging.yml
          File.join(base_path, "#{environment_name}.yml"), # /staging.yml
          File.join(base_path, 'deploy.yml') # /deploy.yml
        ]

        files.each { |file|  return file if File.exists?(file) }

        raise "Could not locate configuration file in path [#{base_path}]"
      end

      def configuration_data
        raise "Configuration file [#{configuration_file}] not found!" unless File.exists?(configuration_file)
        File.read(configuration_file)
      end

      def project_name
        specified_project_name || 'unnamed_project'
      end

      def extract_project_name(data)
        data[environment_name][:project] || project_name
      end

      def repository_depth(data, depth = 0)
        raise 'no repository found' unless data.respond_to?(:has_key?)
        return depth if data.has_key?('repository')
        repository_depth(data.values.first, depth + 1)
      end

      # is this data hash a bottom-level data hash without an environment name?
      def needs_environment_scoping?(data)
        repository_depth(data) == 0
      end

      # is this data hash an environment data hash without a project name?
      def needs_project_scoping?(data)
        repository_depth(data) == 1
      end

      def add_environment_scoping(data)
        return data unless needs_environment_scoping?(data)
        { environment_name => data }
      end

      def add_project_scoping(data)
        return data unless needs_project_scoping?(data)
        { extract_project_name(data) => data }
      end

      def normalize_data(data)
        add_project_scoping(add_environment_scoping(data.clone))
      end

      def load_data
        normalize_data(YAML.load(configuration_data))
      rescue Exception => e
        raise %Q{Error reading configuration file [#{configuration_file}]: "#{e}"}
      end

      def filter_data(data)
        raise "No configuration file defined data for environment [#{environment_name}]" unless data[project_name][environment_name]
        data[project_name][environment_name].merge({
          'environment' => environment_name,
          'project' => project_name
        })
      end

      def fetch
        raise "Cannot determine current environment -- try rake ... to=staging, for example." unless environment_name
        filter_data(load_data)
      end
    end
  end
end
