require File.expand_path(File.dirname(__FILE__)) + '/stock_code/opview_filter'

module Twstock
    class StockCode
        include OpviewFilter
    end
end
