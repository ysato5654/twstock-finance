#! /opt/local/bin/ruby
# coding: utf-8

require 'optparse'

require File.dirname(File.realpath(__FILE__)) + '/../lib/twstock/finance'
require File.dirname(File.realpath(__FILE__)) + '/../lib/twstock/stock_code'

Year    = '2020'
Month   = 'May'
Day     = '10'
Build   = [Day, Month, Year].join(' ')

Version = Build + ' ' + '(' + 'twstock-finance' + ' ' + 'v' + Twstock::Finance::VERSION + ')'

SHOW = ['all', 'twse', 'tpex']
LANGUAGE = ['chinese', 'english']

def parse_option
    opt = OptionParser.new

    option = Hash.new
    option[:lang] = LANGUAGE.first

    opt.on('--show VAL', "show code setting (#{SHOW.join('/')})") { |v| option[:show] = v }
    opt.on('--lang VAL', "language setting (#{LANGUAGE.join('/')}) (default: #{LANGUAGE.first})") { |v| option[:lang] = v }

    opt.parse(ARGV)

    option
end

if $0 == __FILE__

    # parse option
    begin
        option = parse_option

    # display help
    rescue SystemExit => e
        exit(0)

    # invalid option (undefined option)
    rescue Exception => e
        STDERR.puts "#{__FILE__}: #{e} (--help will show valid options)"
        exit(0)
    end

    # invalid option (no option)
    if option[:show].nil?
        STDERR.puts "#{__FILE__}: no option (--help will show valid options)"
        exit(0)
    end

    # invalid option (show setting)
    unless SHOW.include?(option[:show])
        STDERR.puts "#{__FILE__}: invalid option (--help will show valid options)"
        exit(0)
    end

    # invalid option (language setting)
    unless LANGUAGE.include?(option[:lang])
        STDERR.puts "#{__FILE__}: invalid option (--help will show valid options)"
        exit(0)
    end

    filename = File.basename(__FILE__).gsub(File.extname(__FILE__), '')

    STDOUT.puts filename + ' ' + Version
    STDOUT.puts

    begin
        twstock = Twstock::StockCode.new
    rescue Exception => e
        STDERR.puts "#{__FILE__}:#{__LINE__}: #{e.message} (#{e.class})"
        exit(0)
    end

    # header
    header = Twstock::StockCode::KEY[option[:lang].to_sym]
    STDOUT.puts header.join("\s\|\s")
    STDOUT.puts [header.map { |e| "-" * e.length }].join("\s\|\s")

    # body
    twstock.codes_info.each do |code_info|
        case option[:show]
        when SHOW[0]
            STDOUT.puts code_info.values.join("\s\|\s")
        when SHOW[1]
            if code_info['market'] == '上市'
                STDOUT.puts code_info.values.join("\s\|\s")
            end
        when SHOW[2]
            if code_info['market'] == '上櫃'
                STDOUT.puts code_info.values.join("\s\|\s")
            end
        end
    end

end
