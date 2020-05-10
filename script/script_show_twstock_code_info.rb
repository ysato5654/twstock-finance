#! /opt/local/bin/ruby
# coding: utf-8

require 'optparse'

require File.dirname(File.realpath(__FILE__)) + '/../lib/twstock/finance'
require File.dirname(File.realpath(__FILE__)) + '/../lib/twstock/stock_code'

Year    = '2020'
Month   = 'May'
Day     = '10b'
Build   = [Day, Month, Year].join(' ')

Version = Build + ' ' + '(' + 'twstock-finance' + ' ' + 'v' + Twstock::Finance::VERSION + ')'

SHOW = ['all', 'twse', 'tpex']
LANGUAGE = ['chinese', 'english']
CODE_INFO_CONNECTION = "\s\|\s"

def parse_option
    opt = OptionParser.new

    option = Hash.new
    option[:lang] = LANGUAGE.first

    opt.on('--show VAL', "show code setting (#{SHOW.join('/')})") { |v| option[:show] = v }
    opt.on('--lang VAL', "language setting (#{LANGUAGE.join('/')}) (default: #{LANGUAGE.first})") { |v| option[:lang] = v }

    opt.parse(ARGV)

    # no necessary option
    if option[:show].nil?
        STDERR.puts "#{__FILE__}: no option: --show (--help will show valid options)"
        raise SystemExit
    end

    # invalid option (show setting)
    raise OptionParser::InvalidArgument unless SHOW.include?(option[:show])

    # invalid argument (language setting)
    raise OptionParser::InvalidArgument unless LANGUAGE.include?(option[:lang])

    option
end

def show_twstock_code_info(show:, lang:)
    begin
        twstock = Twstock::StockCode.new
    rescue Exception => e
        STDERR.puts "#{__FILE__}:#{__LINE__}: #{e.message} (#{e.class})"
        return
    end

    # header
    header = Twstock::StockCode::KEY[lang.to_sym]
    STDOUT.puts header.join("\s\|\s")
    STDOUT.puts [header.map { |e| "-" * e.length }].join(CODE_INFO_CONNECTION)

    # body
    twstock.codes_info.each do |code_info|
        case show
        when SHOW[0]
            STDOUT.puts code_info.values.join(CODE_INFO_CONNECTION)
        when SHOW[1]
            if code_info['market'] == '上市'
                STDOUT.puts code_info.values.join(CODE_INFO_CONNECTION)
            end
        when SHOW[2]
            if code_info['market'] == '上櫃'
                STDOUT.puts code_info.values.join(CODE_INFO_CONNECTION)
            end
        end
    end
end

if $0 == __FILE__

    # parse option
    begin
        option = parse_option

    # display help or no necessary option fail
    rescue SystemExit => e
        exit(0)

    # invalid option (undefined option)
    rescue Exception => e
        STDERR.puts "#{__FILE__}: #{e} (--help will show valid options)"
        exit(0)
    end

    filename = File.basename(__FILE__).gsub(File.extname(__FILE__), '')

    STDOUT.puts filename + ' ' + Version
    STDOUT.puts

    show_twstock_code_info(:show => option[:show], :lang => option[:lang])

end
