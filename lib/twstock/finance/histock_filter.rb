require 'histock/filter'
require File.expand_path(File.dirname(__FILE__)) + '/error'

module Twstock
    module HistockFilter
        def financial_statements(code:, period:)
            histock = Histock::Filter.new

            case period
            when 'month' then raise NoSupportedFunction
            when 'quarter'
                financial_data = merge(
                    :list1 => histock.income_statement(code),
                    :list2 => histock.profit_ratio(code),
                    :list3 => histock.income_rate(code, period))

            when 'year' then raise NoSupportedFunction
            else raise ArgumentError
            end

            financial_data
        end

        private

        def merge(list1:, list2:, list3:)
            list = Array.new

            key = '年度/季別'

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
    end
end
