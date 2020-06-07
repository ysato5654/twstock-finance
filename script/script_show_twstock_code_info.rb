#! /opt/local/bin/ruby
# coding: utf-8

require File.dirname(File.realpath(__FILE__)) + '/command_line_option'

require File.dirname(File.realpath(__FILE__)) + '/../lib/twstock/finance'
require File.dirname(File.realpath(__FILE__)) + '/../lib/twstock/stock_code'

Year    = '2020'
Month   = 'Jun'
Day     = '07'
Build   = [Day, Month, Year].join(' ')

Version = Build + ' ' + '(' + 'twstock-finance' + ' ' + 'v' + Twstock::Finance::VERSION + ')'

Show = [:all, :twse, :tpex]
Language = [:chinese, :english]
Options = [
    {:short => 's', :long => 'show', :arg => Show, :description => "show code setting (#{Show.join('/')})"},
    {:short => 'l', :long => 'lang', :arg => Language, :description => "language setting (#{Language.join('/')}) (default: #{Language.first})"}
]

CODE_INFO_CONNECTION = "\s\|\s"

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
        when Show[0]
            STDOUT.puts code_info.values.join(CODE_INFO_CONNECTION)
        when Show[1]
            if code_info['market'] == '上市'
                STDOUT.puts code_info.values.join(CODE_INFO_CONNECTION)
            end
        when Show[2]
            if code_info['market'] == '上櫃'
                STDOUT.puts code_info.values.join(CODE_INFO_CONNECTION)
            end
        end
    end
end

if $0 == __FILE__

    command_line_option = TweetActivityScript::CommandLineOption.new(:params => Options)

    # parse option
    begin
        option = command_line_option.parse

    # display help or no necessary option fail
    rescue SystemExit => e
        exit(0)

    rescue TweetActivityScript::MissingOption => e
        STDERR.puts "#{__FILE__}: #{e.message} (--help will show valid options)"
        exit(0)

    # invalid option (undefined option) or missing argument or invalid argument
    rescue Exception => e
        STDERR.puts "#{__FILE__}: #{e} (--help will show valid options)"
        exit(0)

    end

    if option[:show].nil? or option[:lang].nil?
        STDERR.puts "#{__FILE__}: missing option (--help will show valid options)"
        exit(0)
    end

    filename = File.basename(__FILE__).gsub(File.extname(__FILE__), '')

    STDOUT.puts filename + ' ' + Version
    STDOUT.puts

    show_twstock_code_info(:show => option[:show], :lang => option[:lang])

end
