require File.dirname(File.realpath(__FILE__)) + '/opview_simplefilter'

module Twstock
    module OpviewFilter
        attr_reader :codes_info, :codes, :twse, :tpex

        KEY = {
            :chinese => ['類型', '公司代號', '公司名稱', '產業別'],
            :english => ['market', 'code', 'company', 'sector']
        }

        MARKET = ['上市', '上櫃', '興櫃', '創櫃']

        def initialize
            @codes_info = Array.new
            @codes = Array.new
            @twse = Array.new
            @tpex = Array.new

            opview = Twstock::OpviewSimplefilter.new
            parse(opview.codes)
        end

        private

        def parse(list)
            # codes_info
            list.zip(Twstock::OpviewSimplefilter::ID).each do |codes, id|
                if codes.first == KEY[:chinese]
                    # remove header
                    # convert chinese to english in key, but in value
                    # convert array to hash
                    @codes_info.concat(codes[1..-1].map { |e| KEY[:english].zip(e).to_h })

                # no header => raise error
                else
                    raise TableHeaderError if id != 'p10' # patch (special case)

                    # CANNOT remove header
                    # convert chinese to english in key, but in value
                    # convert array to hash
                    @codes_info.concat(codes[0..-1].map { |e| KEY[:english].zip(e).to_h })
                end
            end

            # codes / twse / tpex
            @codes_info.each do |code|
                # codes
                @codes.push code['code']

                case code['market']
                # twse
                when MARKET[0] then @twse.push code['code']
                # tpex
                when MARKET[1] then @tpex.push code['code']
                end
            end
        end

        class Error < StandardError
        end

        class TableHeaderError < Error
            attr_reader :message

            def initialize
                @message = 'table has no header'
            end
        end
    end
end

class Integer
    def is_zero?
        self == 0
    end
end
