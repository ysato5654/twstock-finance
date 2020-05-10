# Twstock::Finance

## Usage

### Get Stock Codes

```rb
require 'twstock/stock_code'

twstock = Twstock::StockCode.new
twstock.codes
# => all codes
# [
#   "1316",
#   "1704",
#      :
# ]

twstock.twse
# => codes in twse
# [
#   "1316",
#   "1704",
#      :
# ]

twstock.tpex
# => codes in tpex
# [
#   "1742",
#   "1787",
#      :
# ]
```
