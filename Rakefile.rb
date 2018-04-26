#--*-coding:utf-8-*--

require 'rake/testtask'

$LOAD_PATH << File.dirname(__FILE__)

require 'Autoload'

$logger = Logger.new(AppConfig.log.path)
$logger.level=(AppConfig.log.level)

task :default => :help

namespace :dicebot do
  desc "Show all dicebots"
  task :list do
    puts FileList['diceBot/*.rb']
    .map{|file|File.basename(file, ".rb")}
    .exclude(/^(_Template|DiceBot)$/)
    .join("\n")
  end

  desc "Show dicebot info"
  task :info, ['name'] do |task, arg|
    bot = DiceBotLoader.load(arg.name)
    if(bot)
      puts "ゲームシステム：" << bot.info['name'] << "\n" <<
           "説明文：\n" << bot.info['info']
    else
      puts "No dicebot exists for \"#{arg.name}\""
    end
  end
  
  task :run, ['command', 'name'] do |task, arg|
    $logger.level = Logger::DEBUG
    unless (arg['name'])
      name = nil
    else
      name = arg.name
    end
    bot = DiceBotLoader.load(name)
    puts bot.execute(arg.command)
  end
end

desc "Show help text"
task :help do
  puts <<'EOS'
Bcdice supports below tasks

rake help
  # Show this document

rake test
  # Run Rake::TestTask unit tests

rake dicebot:list
  # Show all support dicebots
rake dicebot:info[dicebotname]
  # Show all support dicebots
rake dicebot:run[command,dicebotname]
EOS
end

Rake::TestTask.new do |t|
  t.libs << ["test"]
  t.test_files = FileList['test/testall.rb']
  t.verbose = false
  t.warning = false
  t.loader = 'testrb'
end