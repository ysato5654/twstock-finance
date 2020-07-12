require 'histock/filter'
require 'date'
require File.expand_path(File.dirname(__FILE__)) + '/error'

module Twstock
    module HistockFilter
        def financial_statements(code:, period:)
            histock = Histock::Filter.new

            case period
            when 'month' then raise NoSupportedFunction
            when 'quarter'
                financial_data = merge(
                    :key => '年度/季別',
                    :list1 => histock.income_statement(code),
                    :list2 => histock.profit_ratio(code),
                    :list3 => histock.income_rate(code, period))

            when 'year' then raise NoSupportedFunction
            else raise ArgumentError
            end

            financial_data
        end

        def corporate_value(code:)
            histock = Histock::Filter.new

            corporate_value = merge(
                :key => '年度/月份',
                :list1 => histock.price_to_earning_ratio(code),
                :list2 => histock.price_book_ratio(code),
                :list3 => [])

            corporate_value
            # => [
            #        {
            #            "年度/月份"=>"2020/06",
            #            "本益比"=>20.44,
            #            "股價淨值比"=>4.89
            #        },
            #        {},
            #        :
            #    ]
        end

        private

        def merge(key:, list1:, list2:, list3:)
            list = Array.new

            period_list = list1.map { |e| e[key] } + list2.map { |e| e[key] } + list3.map { |e| e[key] }
            period_list.uniq!

            period_list.each do |period|
                # find data out corresponding to period
                find1 = list1.find_all { |e| period == e[key] }
                find2 = list2.find_all { |e| period == e[key] }
                find3 = list3.find_all { |e| period == e[key] }

                # not found => pad empty hash
                find1.push Hash.new if find1.size == 0
                find2.push Hash.new if find2.size == 0
                find3.push Hash.new if find3.size == 0

                # multiple found
                raise MergeError unless find1.size == 1
                raise MergeError unless find2.size == 1
                raise MergeError unless find3.size == 1

                list.push find1.first.merge(find2.first).merge(find3.first)
            end

            list
        end

        private

        def parse_dividend_policy_table_value(value)
            if value.is_not_applicable? then nil
            elsif value.empty? then value
            elsif value.is_year? then value#.to_i
            elsif value.is_date? then value
            #elsif value.is_date? then Date.parse(value)
            elsif value.is_currency? then value.to_currency
            else
                puts 'ERROR'
                while true; end
            end
        end
    end
end

class String
    def is_not_applicable?
        self == '-'
    end

    def is_year?
        (self =~ /^[1-2][0-9]{3}$/).nil? ? false : true
    end

    def is_date?
        (self =~ /^[0-1][0-9]\/[0-3][0-9]$/).nil? ? false : true
    end

    def is_currency?
        (self =~ /^[+-]?[0-9]*[\,]?[0-9]*[\.]?[0-9]+$/).nil? ? false : true
    end

    def to_currency
        unless self.is_currency?
            STDERR.puts "#{__FILE__}:#{__LINE__}: argument - #{self}"
            raise ArgumentError
        end

        self.gsub(/[\,]/, '').to_f
    end
end
