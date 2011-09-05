#--
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# Version 2, December 2004
#
# Copyleft shura [shura1991@gmail.com]
#
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'optparse'
require 'singleton'
require 'shellwords'

require 'efreesms'

class EFreeSMS
  class Bin
    include Singleton

    def run
      reset
      parse_opts

      unless @user and @editor and @country and @number
        $stderr.puts "Please, set up the client"
        exit 1
      end

      EFreeSMS::SMS.send(@user, @country, @number, edit)
    end

    def reset
      @editor, @country, @number, @user = ENV['EDITOR'], ENV['COUNTRY'], nil, ENV['SMSUSER']
    end

    def parse_opts
      OptionParser.new {|opts|
        opts.banner = "Usage: #$0 [options] phone"

        opts.on('-e', '--editor EDITOR', 'Select editor') {|ed|
          @editor = ed
        }

        opts.on('-c', '--country COUNTRY', 'Select recipients\' country') {|c|
          @country = c
        }

        opts.on('-u', '--user USER', 'Select your name in sms') {|u|
          @user = u
        }

        opts.on_tail('-v', '--version', 'Show version') {
          puts "e-freesms sender #{EFreeSMS::VERSION}"
          exit 0
        }
      }.tap {|opts|
        o = opts.parse!(ARGV)

        if o.size != 1
          $stderr.puts opts
          exit 1
        end

        @number = o.first
        @user ||= ENV['USER']
      }
    end

    def edit
      editor = Shellwords.shellwords(@editor)
      file = Tempfile.new(['sms', '.txt']).tap {|x| x.close }.path
      Exec.system(*editor, file)

      File.read(file).tap {
        File.unlink(file)
      }
    end

    private :reset

    def self.run
      instance.run
    end

    module Exec
      module Java
        def system(file, *args)
          require 'spoon'
          Process.waitpid(Spoon.spawnp(file, *args))
        rescue Errno::ECHILD => e
          raise "error exec'ing #{file}: #{e}"
        end
      end

      module MRI
        def system(file, *args)
          Kernel::system(file, *args) #or raise "error exec'ing #{file}: #{$?}"
        end
      end

      extend RUBY_PLATFORM =~ /java/ ? Java : MRI
    end
  end
end
