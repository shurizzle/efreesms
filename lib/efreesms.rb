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

require 'RMagick'
require 'tempfile'
require 'nokogiri'
require 'httpclient'

require 'efreesms/version'

class EFreeSMS
  class Captcha
    def self.download (browser, dest)
      File.open(dest, 'w') {|file|
        browser.get('http://www.e-freesms.com/captcha.php', {}, {'Referer' => 'http://www.e-freesms.com/sms.php'}) {|data|
          file.write(data)
        }
      }
    end

    def self.resolve (browser)
      ''.tap {|res|
        Dir.mktmpdir {|d|
          Dir.chdir(d) {|d|
            download(browser, File.join(File.realpath(d), 'captcha.jpg'))
            Magick::Image.read('captcha.jpg')[0].resize(130, 50).negate.despeckle.write('captcha.tif')
            system('tesseract', 'captcha.tif', 'captcha', 2 => '/dev/null')
            res.replace File.read('captcha.txt').strip
            %w{captcha.jpg captcha.tif captcha.txt}.each {|f|
              File.unlink(f)
            }
          }
        }
      }
    end
  end

  class SMS
    class << self
      def send (user, country, number, text)
        $stderr.sync = true
        txts = text.split(//).each_slice(120 - user.size - 2).map(&:join)

        txts.each_with_index {|txt, i|
          begin
            $stderr.print "\rsending #{i + 1}/#{txts.size}"
            real_send(country, number, ("%s: %s" % [user, txt]))
          rescue Exception => e
            $stderr.puts e
            retry
          end
        }

        $stderr.puts "\nSent."
      end

      protected
      def real_send (country, number, text)
        browser = HTTPClient.new(agent_name: EFreeSMS::USERAGENT)

        countries = Hash[Nokogiri::HTML(browser.get('http://www.e-freesms.com/sms.php').body).xpath('//select[@name="country"]/option').select {|x| !x['value'].empty? }.map {|x| [x.text.gsub(/\s*\(.+?\)\s*/, '').downcase, x['value']] }]

        country = country.to_s.downcase
        country = countries[country] if countries[country]
        raise "Country not valid" unless countries.values.include?(country)

        body = browser.post('http://www.e-freesms.com/s4b8usba.php', {
          'country' => country,
          'phone'   => (country + number),
          'text'    => text,
          'vercode' => EFreeSMS::Captcha.resolve(browser),
          'submit'  => 'SEND SMS'
        }, {
          'Referer'     => 'http://www.e-freesms.com/sms.php'
        }).body

        unless body =~ /Your SMS has been sent/i
          $stderr.puts " ERROR, retrying."
          raise
        end
      end
    end
  end
end
