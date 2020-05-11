# Twstock::Finance

## Usage

### Get Stock Codes

You can get lists of stock code on Taiwan market ('上市' / '上櫃' / '興櫃' / '創櫃')

```rb
require 'twstock/stock_code'

twstock = Twstock::StockCode.new
twstock.codes
# => all codes on 4 type of market namely, '上市', '上櫃', '興櫃' and '創櫃'
# [
#   "1316",
#   "1704",
#      :
# ]

twstock.twse
# => codes in twse ('上市')
# [
#   "1316",
#   "1704",
#      :
# ]

twstock.tpex
# => codes in tpex ('上櫃')
# [
#   "1742",
#   "1787",
#      :
# ]
```
