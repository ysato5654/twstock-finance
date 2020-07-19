#! /opt/local/bin/ruby
# coding: utf-8

require 'optparse'

require File.dirname(File.realpath(__FILE__)) + '/command_line_option'

require File.dirname(File.realpath(__FILE__)) + '/../lib/twstock/finance'
require File.dirname(File.realpath(__FILE__)) + '/../lib/twstock/stock_code'

Year    = '2020'
Month   = 'Jul'
Day     = '19'
Build   = [Day, Month, Year].join(' ')

Version = Build + ' ' + '(' + 'twstock-finance' + ' ' + 'v' + Twstock::Finance::VERSION + ')'

module ScriptTwstock
    class StockFundamental
        attr_reader :market_list, :sector_list

        def initialize
            @market_list = Twstock::StockCode::MARKET
            # => ['上市', '上櫃', '興櫃', '創櫃']

            @sector_list = [
                '化學工業',
                '文化創意業',
                '半導體業',
                '生技醫療業',
                '光電業',
                '汽車工業',
                '其他電子業',
                '金融業',
                '建材營造',
                '航運業',
                '通信網路業',
                '貿易百貨',
                '塑膠工業',
                '電子零組件業',
                '電腦及週邊設備業',
                '電機機械',
                '鋼鐵工業',
                '觀光事業'
            ]
        end

        public

        def get_codes(market:, sector:)
            unless @market_list.include?(market)
                STDERR.puts "#{__FILE__}:#{__LINE__}: market=#{market} (ArgumentError)"
                return []
            end

            unless @sector_list.include?(sector)
                STDERR.puts "#{__FILE__}:#{__LINE__}: sector=#{sector} (ArgumentError)"
                return []
            end

            begin
                twstock = Twstock::StockCode.new
            rescue Exception => e
                STDERR.puts "#{__FILE__}:#{__LINE__}: #{e.message} (#{e.class})"
                return []
            end

            twstock.codes_info.select { |code_info| code_info['market'] == market and code_info['sector'] == sector }
        end

        def get_latest_financial_statement(code:)
            twstock_finance = Twstock::Finance.new

            begin
                financial_statements = twstock_finance.financial_statements(:code => code, :period => 'quarter')
            rescue Exception => e
                STDERR.puts "#{__FILE__}:#{__LINE__}: code=#{code} (#{e.message})"
                return {}
            end

            financial_statement = financial_statements.first
        end

        def get_company_profile(code:)
            twstock_finance = Twstock::Finance.new

            begin
                company_profile = twstock_finance.company_profile(:code => code)
            rescue Exception => e
                STDERR.puts "#{__FILE__}:#{__LINE__}: code=#{code} (#{e.message})"
                return {}
            end

            company_profile
        end
    end

    class Display

        INJECT_CHAR = "\t"

        HEADER = {
            :code => 'code',
            :company => 'company',
            :issued_shares => '已發行普通股',
            :PER => '本益比',
            :PBR => '股價淨值比',
            :ROE => '近四季ROE',
            :ROA => '近四季ROA',
        }

        def initialize
        end

        public

        def version
            filename = File.basename(__FILE__).gsub(File.extname(__FILE__), '')

            STDOUT.print filename + ' ' + Version
            new_line
            new_line
        end

        def thead
            STDOUT.print HEADER.keys.join(INJECT_CHAR)
            new_line
        end

        def tbody_1(h1)
            STDOUT.print [
                h1[HEADER[:code]],
                h1[HEADER[:company]],
            ].join(INJECT_CHAR)
        end

        def tbody_2(h2, h3)
            STDOUT.print [
                h2[HEADER[:issued_shares]],
                h2[HEADER[:PER]],
                h2[HEADER[:PBR]],
                h3[HEADER[:ROE]],
                h3[HEADER[:ROA]],
            ].join(INJECT_CHAR)
        end

        def tbody_inject
            STDOUT.print INJECT_CHAR
        end

        def new_line
            STDOUT.puts
        end
    end
end

if $0 == __FILE__

    $stdout.sync = true

    twstock = ScriptTwstock::StockFundamental.new

    options = [
        {:short => 'm', :long => 'market', :arg => twstock.market_list, :description => "market (#{twstock.market_list.join('/')})"},
        {:short => 's', :long => 'sector', :arg => twstock.sector_list, :description => "sector (#{twstock.sector_list.join('/')})"}
    ]

    command_line_option = TweetActivityScript::CommandLineOption.new(:params => options)

    # parse option
    begin
        option = command_line_option.parse

    # display help or no necessary option fail
    rescue SystemExit => e
        exit(1) # error exit

    rescue TweetActivityScript::MissingOption => e
        STDERR.puts "#{__FILE__}: #{e.message} (--help will show valid options)"
        exit(1) # error exit

    # invalid option (undefined option) or missing argument or invalid argument
    rescue Exception => e
        STDERR.puts "#{__FILE__}: #{e} (--help will show valid options)"
        exit(1) # error exit

    end

    if option[:market].nil? or option[:sector].nil?
        STDERR.puts "#{__FILE__}: missing option (--help will show valid options)"
        exit(1) # error exit
    end

    display = ScriptTwstock::Display.new
    display.version

    codes_info = twstock.get_codes(:market => option[:market], :sector => option[:sector])

    display.thead

    codes_info.each do |code_info|
        display.tbody_1(code_info)
        display.tbody_inject

        company_profile = twstock.get_company_profile(:code => code_info['code'])

        financial_statement = twstock.get_latest_financial_statement(:code => code_info['code'])
        # => {
        #        '年度/季別' => '2020Q1',
        #        '營收' => 176296, '毛利' => 142795, '營業利益' => 127061, '稅前淨利' => 54618, '稅後淨利' => 34124,
        #        '毛利率' => 81.0, '營業利益率' => 72.07, '稅前淨利率' => 30.98, '稅後淨利率' => 19.36,
        #        '近四季ROE' => 3.19, '近四季ROA' => 1.81
        #    }

        if company_profile.empty? == false and financial_statement.empty? == false
            display.tbody_2(company_profile, financial_statement)
        end

        display.new_line
    end

end
