require 'optparse'

module Nitra
  class CommandLine
    attr_reader :configuration

    def initialize(configuration, argv)
      @configuration = configuration

      OptionParser.new do |opts|
        opts.banner = "Usage: nitra [options] [spec_filename [...]]"

        opts.on("--burndown FILENAME", String, "Produce a burndown report showing the test execution times") do |filename|
          configuration.burndown_report = filename
        end

        opts.on("-c", "--cpus NUMBER", Integer, "Specify the number of CPUs to use on the host, or if specified after a --slave, on the slave") do |n|
          configuration.set_process_count n
        end

        opts.on("--cucumber [PATTERN1,PATTERN2]", Array,
                "Full cucumber run, causes any files you list manually to be ignored.",
                "Default pattern is \"features/**/*.feature\"."
               ) do |patterns|
          configuration.add_framework("cucumber", patterns || ["features/**/*.feature"])
        end

        opts.on("--debug", "Print debug output") do
          configuration.debug = true
        end

        opts.on("-p", "--print-failures", "Print failures immediately when they occur") do
          configuration.print_failures = true
        end

        opts.on("-q", "--quiet", "Quiet; don't display progress bar") do
          configuration.quiet = true
        end

        opts.on("--rake-after-runner task:1,task:2,task:3", Array, "The list of rake tasks to run, once per runner, in the runner's environment, just before the runner exits") do |rake_tasks|
          configuration.add_rake_task(:after_runner, rake_tasks)
        end

        opts.on("--rake-before-runner task:1,task:2,task:3", Array, "The list of rake tasks to run, once per runner, in the runner's environment, after the runner starts") do |rake_tasks|
          configuration.add_rake_task(:before_runner, rake_tasks)
        end

        opts.on("--rake-before-worker task:1,task:2,task:3", Array, "The list of rake tasks to run, once per worker, in the worker's environment, before the worker starts") do |rake_tasks|
          configuration.add_rake_task(:before_worker, rake_tasks)
        end

        opts.on("-r", "--reset", "Reset database, equivalent to --rake-before-worker db:reset") do
          configuration.add_rake_task(:before_worker, "db:reset")
        end

        opts.on("--rspec [PATTERN1,PATTERN2]", Array,
                "Full rspec run, causes any files you list manually to be ignored.",
                "Default pattern is \"spec/**/*_spec.rb\"."
               ) do |patterns|
          configuration.add_framework("rspec", patterns || ["spec/**/*_spec.rb"])
        end

        opts.on("--slave-mode", "Run in slave mode; ignores all other command-line options") do
          configuration.slave_mode = true
        end

        opts.on("--slave CONNECTION_COMMAND", String, "Provide a command that executes \"nitra --slave-mode\" on another host") do |connection_command|
          configuration.add_slave connection_command
        end

        opts.on("--split-files", "Split test files and run the scenarios in parallel") do
          configuration.split_files = true
        end

        opts.on("--start-framework FRAMEWORK", String, "Start all workers with this framework first.  The default is to start a mixture of workers on each framework.") do |framework|
          configuration.start_framework = framework
        end

        opts.on("--tags @TAG", "Only run these Cucumber tags") do |tags|
          configuration.tags = tags
        end

        opts.on("-e", "--environment ENV", String, "Set the RAILS_ENV to load") do |env|
          configuration.environment = env
        end

        opts.on("--retry EXCEPTION", String, "Retry tests that fail with the given exception, which can be a plain string or a /regex/.") do |exception|
          if exception[0] == '/' && exception[-1] == '/'
            configuration.exceptions_to_retry = Regexp.new(exception[1..-2])
          else
            configuration.exceptions_to_retry = Regexp.new(Regexp.escape(exception))
          end
        end

        opts.on("--attempts N", Integer, "Maximum number of times to try tests that fail with the --retry exceptions") do |max_attempts|
          configuration.max_attempts = max_attempts
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end.parse!(argv)

      puts "You should use the --rspec and/or --cucumber options to run some tests." if argv.empty? && configuration.frameworks.empty? && !configuration.slave_mode
    end
  end
end
