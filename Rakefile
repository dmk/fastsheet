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

desc 'Run unit specs'
task 'spec:unit' do
  @logger.info('Running unit specs')
  sh 'bundle exec rspec --format documentation spec/unit'
end

desc 'Run integration specs'
task 'spec:integration' => [:build] do
  @logger.info('Running integration specs')
  sh 'INTEGRATION=1 bundle exec rspec --format documentation spec/integration'
end

desc 'Run tests (unit + integration)'
task :test do
  Rake::Task['spec:unit'].invoke
  Rake::Task['spec:integration'].invoke
end

task default: [:test]

namespace :lint do
  desc 'Run Ruby lint (RuboCop)'
  task :ruby do
    sh 'bundle exec rubocop'
  end

  desc 'Run Rust lint (fmt --check, check, clippy)'
  task :rust do
    Dir.chdir('ext/fastsheet') do
      sh 'cargo fmt -- --check'
      sh 'cargo check --all'
      sh 'cargo clippy --all-targets -- -D warnings'
    end
  end
end

desc 'Run all linters'
task :lint do
  Rake::Task['lint:ruby'].invoke
  Rake::Task['lint:rust'].invoke
end

desc 'Format Ruby and Rust code'
task :format do
  # Ruby: RuboCop auto-correct
  sh 'bundle exec rubocop -A'

  # Rust: cargo fmt (write changes)
  Dir.chdir('ext/fastsheet') do
    sh 'cargo fmt'
  end
end
