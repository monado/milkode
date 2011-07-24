# -*- coding: utf-8 -*-
require 'optparse'
require 'codestock/cdstk/cli_cdstksub'
require 'codestock/cdstk/cdstk'
require 'codestock/common/dbdir.rb'
require 'codestock/cdweb/cli_cdweb'
include CodeStock

module CodeStock
  class CLI_Cdstk
    def self.execute(stdout, arguments=[])
      opt = OptionParser.new <<EOF
#{File.basename($0)} COMMAND [ARGS]

The most commonly used #{File.basename($0)} are:
  init        Init db.
  add         Add packages.
  update      Update packages.
  web         Run web-app.
  remove      Remove packages.
  list        List packages. 
  pwd         Disp current db.
  cleanup     Cleanup garbage records.
  rebuild     Rebuild db.
  dump        Dump records.
EOF

      subopt = Hash.new
      suboptions = Hash.new
      
      subopt['init'], suboptions['init'] = CLI_Cdstksub.setup_init
      subopt['add'] = CLI_Cdstksub.setup_add
      subopt['update'] = OptionParser.new("#{File.basename($0)} update content1 [content2 ...]")

      remove_options = {:force => false, :verbose => false}
      subopt['remove'] = OptionParser.new("#{File.basename($0)} remove content1 [content2 ...]")
      subopt['remove'].on('-f', '--force', 'Force remove.') { remove_options[:force] = true }
      subopt['remove'].on('-v', '--verbose', 'Be verbose.') { remove_options[:verbose] = true }

      list_options = {:verbose => false}
      subopt['list'] = OptionParser.new("#{File.basename($0)} list content1 [content2 ...]")
      subopt['list'].on('-v', '--verbose', 'Be verbose.') { list_options[:verbose] = true }
      
      subopt['pwd'] = OptionParser.new("#{File.basename($0)} pwd")
      subopt['cleanup'], suboptions['cleanup'] = CLI_Cdstksub.setup_cleanup
      subopt['rebuild'] = OptionParser.new("#{File.basename($0)} rebuild")
      subopt['dump'] = OptionParser.new("#{File.basename($0)} dump")
      subopt['web'], suboptions['web'] = CLI_Cdstksub.setup_web

      opt.order!(arguments)
      subcommand = arguments.shift

      if (subopt[subcommand])
        subopt[subcommand].parse!(arguments) unless arguments.empty?
        init_default = suboptions['init'][:init_default]

        db_dir = select_dbdir(subcommand, init_default)
        obj = Cdstk.new(stdout, db_dir)

        case subcommand
        when 'init'
          FileUtils.mkdir_p db_dir if (init_default)
          obj.init 
        when 'update'
          obj.update(arguments)
        when 'add'
          obj.add(arguments)
        when 'remove'
          obj.remove(arguments, remove_options[:force], remove_options[:verbose])
        when 'list'
          obj.list(arguments, list_options[:verbose])
        when 'pwd'
          obj.pwd
        when 'cleanup'
          obj.cleanup(suboptions[subcommand])
        when 'rebuild'
          obj.rebuild
        when 'dump'
          obj.dump
        when 'web'
          CodeStock::CLI_Cdweb.execute_with_options(stdout, suboptions[subcommand])
        end
      else
        if subcommand
          $stderr.puts "#{File.basename($0)}: '#{subcommand}' is not a #{File.basename($0)} command. See '#{File.basename($0)} --help'"
        else
          stdout.puts opt.help
        end
      end
    end

    private

    def self.select_dbdir(subcommand, init_default)
      if (subcommand == 'init')
        if (init_default)
          db_default_dir
        else
          '.'
        end
      else
        if (dbdir?('.') || !dbdir?(db_default_dir))
          '.'
        else
          db_default_dir
        end
      end
    end
 
  end
end
