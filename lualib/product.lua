return {
    [1] = {product=1, price = 10.00,  card = 10 + 1,},
    [2] = {product=2, price = 20.00,  card = 20 + 4,},
    [3] = {product=3, price = 50.00,  card = 50 + 15},
    [4] = {product=4, price = 100.00, card = 100 + 35},

    -- 抽奖商品
    [6] = {product=6, price = 2.00,  random_tbl={[3]=1},                  show_tbl={ 5,  6,   7,   8,   9,  10,  11,  12}},
    [7] = {product=7, price = 5.00,  random_tbl={[6]=1, [ 7]=1},          show_tbl={ 5,  8,  12,  14,  15,  16,  18,  20}},
    [8] = {product=8, price = 10.00, random_tbl={[12]=1, [13]=1},         show_tbl={10, 15,  20,  26,  36,  40,  46,  50}},
    [9] = {product=9, price = 18.00, random_tbl={[24]=1, [23]=1, [22]=1}, show_tbl={20, 30,  42,  48,  56,  66,  78,  90}},
    [10]= {product=10,price = 30.00, random_tbl={[40]=1, [39]=1, [38]=1}, show_tbl={32, 35,  58,  78,  98, 116, 138, 150}},
    [11]= {product=11,price = 50.00, random_tbl={[68]=1, [67]=1, [66]=1}, show_tbl={55, 58,  98, 138, 166, 198, 226, 248}},

    -- 代理
    [12]={product=12, price = 300.00, proxy_card=300 + 100}
}
