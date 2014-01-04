
require "cdq/version"
require "cdq/generators"

module CDQ
  class CommandLine
    HELP_TEXT = %{Usage:
    cdq [options] <command> [arguments]

Commands:
    cdq init                         # Add boilerplate setup to use CDQ
    cdq create model <model>         # Create a model and associated files

Options:
    }

    attr_reader :singleton_options_passed

    def option_parser(help_text = HELP_TEXT)
      OptionParser.new do |opts|
        opts.banner = help_text

        opts.on("-v", "--version", "Print Version") do
          @singleton_options_passed = true
          puts CDQ::VERSION
        end

        opts.on("-h", "--help", "Show this message") do
          @singleton_options_passed = true
          puts opts
        end
      end
    end

    def self.run_all

      actions = { "init" => InitAction, "create" => CreateAction }

      cli = self.new
      opts = cli.option_parser
      opts.order!
      action = ARGV.shift

      if actions[action]
        actions[action].new.run
      elsif !cli.singleton_options_passed
        puts opts
      end

    end
  end

  class InitAction < CommandLine
    HELP_TEXT = %{Usage:
    cdq init [options]

    Run inside a motion directory, it will:
    * Add cdq and ruby-xcdm to Gemfile, if necessary
    * Set rake to automatically run schema:build
    * Create an initial schema file

Options:
    }

    def option_parser
      super(HELP_TEXT).tap do |opts|
        opts.program_name = "cdq init"

        opts.on("-d", "--dry-run", "Do a Dry Run") do
          @dry_run = "dry_run"
        end
      end
    end

    def run
      opts = option_parser
      opts.order!

      unless singleton_options_passed
        CDQ::Generator.new(@dry_run).create('init')

        print "  \u0394  Checking bundle for cdq... "
        unless system('bundle show cdq')
          print "  \u0394  Adding cdq to Gemfile... "
          File.open("Gemfile", "at") do |gemfile|
            gemfile.puts("gem 'cdq'")
          end
          puts "Done."
        end

        # print "  \u0394  Checking bundle for ruby-xcdm... "
        # unless system('bundle show ruby-xcdm')
        #   print "  \u0394  Adding ruby-xcdm to Gemfile... "
        #   File.open("Gemfile", "at") do |gemfile|
        #     gemfile.puts("gem 'ruby-xcdm'")
        #   end
        #   puts "Done."
        # end

        print "  \u0394  Adding schema:build hook to Rakefile... "
        File.open("Rakefile", "at") do |rakefile|
          rakefile.puts('task :"build:simulator" => :"schema:build"')
        end
        puts "Done."

        puts %{\n  Now edit schemas/0001_initial.rb to define your schema, and you're off and running.  }

      end
    end

  end

  class CreateAction < CommandLine
    HELP_TEXT = %{
Usage:
    cdq create [options] model <model>         # Create a CDQ model and associated test

Options:
    }

    def option_parser
      super(HELP_TEXT).tap do |opts|
        opts.program_name = "cdq create"

        opts.on("-d", "--dry-run", "Do a Dry Run") do
          @dry_run = "dry_run"
        end
      end
    end

    def run
      opts = option_parser
      opts.order!

      object = ARGV.shift

      unless singleton_options_passed
        case object
        when 'model'
          model_name = ARGV.shift
          if model_name

            #camelized = model_name.gsub(/[A-Z]/) { |m| "_#{m.downcase}" }.gsub
            CDQ::Generator.new(@dry_run).create('model', model_name)
          else
            puts "Please supply a model name"
            puts opts
          end
        else
          puts "Invalid object type: #{object}"
          puts opts
        end
      end
    end

  end
end
