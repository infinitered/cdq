
require 'fileutils'

module CDQ
  class Generator
    def initialize(options = nil)
      @dry_run = true if options == 'dry_run'
    end

    def create(template, name = nil)
      insert_from_template(template, name)
    end

    def template_path(template_name)
      sub_path = "templates/#{template_name}/"

      # First check local directory, use that if it exists
      if Dir.exist?("#{Dir.pwd}/#{sub_path}")
        "#{Dir.pwd}/#{sub_path}"
      else # Then check the gem
        begin
          spec = Gem::Specification.find_by_name("cdq")
          gem_root = spec.gem_dir
          "#{gem_root}/#{sub_path}"
        rescue Exception => e
          puts "CDQ - could not find template directory\n"
          nil
        end
      end
    end

    def insert_from_template(template_name, name = nil)
      puts "\n     Creating #{template_name}: #{name}\n\n"

      return unless (@template_path = template_path(template_name))
      files = Dir["#{@template_path}**/*"].select {|f| !File.directory? f}

      if name
        @name = name
        @name_camel_case = @name.split('_').map{|word| word.capitalize}.join
      end

      files.each do |template_file_path_and_name|
        @in_app_path = File.dirname(template_file_path_and_name).gsub(@template_path, '')
        @ext = File.extname(template_file_path_and_name)
        @file_name = File.basename(template_file_path_and_name, @ext)

        @new_file_name = @file_name.gsub('name', @name || 'name')
        @new_file_path_name = "#{Dir.pwd}/#{@in_app_path}/#{@new_file_name}#{@ext}"

        if @dry_run
          puts "\n     Instance vars:"
          self.instance_variables.each{|var| puts "     #{var} = #{self.instance_variable_get(var)}"}
          puts
        end

        if Dir.exist?(@in_app_path)
          puts "     Using existing directory: #{@in_app_path}"
        else
          puts "  \u0394  Creating directory: #{@in_app_path}"
          FileUtils.mkdir_p(@in_app_path) unless @dry_run
        end

        results = load_and_parse_erb(template_file_path_and_name)

        if File.exists?(@new_file_path_name)
          puts "  X  File exists, SKIPPING: #{@new_file_path_name}"
        else
          puts "  \u0394  Creating file: #{@new_file_path_name}"
          File.open(@new_file_path_name, 'w+') { |file| file.write(results) } unless @dry_run
        end
      end

      puts "\n     Done"
    end

    def load_and_parse_erb(template_file_name_and_path)
      template_file = File.open(template_file_name_and_path, 'r').read
      erb = ERB.new(template_file)
      erb.result(binding)
    end
  end
end
