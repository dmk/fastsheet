require 'bundler/setup'
require 'logger'

@logger = Logger.new(STDOUT)

desc 'Build native extension'
task :build do
  ruby 'extconf.rb'
end

desc 'Remove files listed in `.gitignore`'
task :clean do
  # `split` here removes leading `/` from file name if any
  File.read('.gitignore').each_line do |entry|
    Dir.glob(entry.gsub(/(^\/|\n$)/, '')).each do |file_name|
      @logger.info("Removing `#{file_name}`")
      remove_entry(file_name)
    end
  end
end

# TODO
desc 'Run tests'
task :test do
  @logger.info('No tests yet')
end

task default: [:build, :test]
