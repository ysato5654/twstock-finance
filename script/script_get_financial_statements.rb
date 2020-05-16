#! /opt/local/bin/ruby
# coding: utf-8

require File.dirname(File.realpath(__FILE__)) + '/command_line_option'

require File.dirname(File.realpath(__FILE__)) + '/../lib/twstock/finance'

Year    = '2020'
Month   = 'May'
Day     = '16'
Build   = [Day, Month, Year].join(' ')

Version = Build + ' ' + '(' + 'twstock-finance' + ' ' + 'v' + Twstock::Finance::VERSION + ')'

Options = [
    {:short => 'c', :long => 'code', :arg => Integer, :description => 'code'}
]

def show_financial_statements(code:)
    twstock = Twstock::Finance.new

    financial_data = twstock.financial_statements(:code => code, :period => 'quarter')
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

    filename = File.basename(__FILE__).gsub(File.extname(__FILE__), '')

    STDOUT.puts filename + ' ' + Version
    STDOUT.puts

    show_financial_statements(:code => option[:code])

end
