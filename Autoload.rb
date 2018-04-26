#--*-coding:utf-8-*--

$LOAD_PATH << File.dirname(__FILE__)

require 'filelist' unless defined?(FileList)
require 'pp' unless defined?(pp)
require 'kconv' unless defined?(kconv)
require 'webrick' unless defined?(webrick)
require 'json' unless defined?(json)

$main_class = Kernel unless defined?($main_class)

module Autoload
  extend self

  def requireAll(target, recursive = false)
    target.each do |file|
      require file
    end
  end

  def autoload(target, parent = $main_class)
    target.each do |file|
      parent.autoload File.basename(file, '.rb'), file
    end
  end
end

Autoload.requireAll(FileList['module/*.rb'])
Autoload.requireAll(FileList['class/Dice/*.rb'])
require 'class/AbstructDiceBot'
require 'class/DiceBot'
Autoload.autoload(FileList['diceBot/*.rb']
  .exclude(/^(diceBot\/DiceBot\.rb|diceBot\/_.*\.rb|diceBot\/test\.rb)$/),
  DiceBot)
#Autoload.autoload(FileList['dice/*.rb'],DiceBot)
require 'class/Interface'
Autoload.requireAll(FileList['class/Interface/*.rb'])
Autoload.requireAll(FileList['class/API/*.rb'])
