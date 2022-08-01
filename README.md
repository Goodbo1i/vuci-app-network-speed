# Network Speed

For more request/response examples visit: https://documenter.getpostman.com/view/17755621/Uze1wQ3y

## Images

![image](https://user-images.githubusercontent.com/63382553/182170501-8a16c101-8fb1-466b-b6f4-640ab12542ce.png)
![image](https://user-images.githubusercontent.com/63382553/182170744-55fce6d0-4b4d-4db1-b5e9-23778a728f23.png)
![image](https://user-images.githubusercontent.com/63382553/182170946-ce7d9ee3-0805-421a-b2d7-2a839c93c83e.png)





## Needed Installs

#### argparse: https://openwrt.org/packages/pkgdata/lua-argparse
#### cJSON: https://openwrt.org/packages/pkgdata/cjson
#### cURL: https://openwrt.org/packages/pkgdata/lua-argparse
#### socket is needed
#### vuci.utils is needed

## Getting started

This Collection contains sample requests.

It contains following requests
* Login
* Get full/filtered server list
* Begin network speed test
* Get test results
* Get user info
* Get best server for a user

### Usage

### POST method

|Parameters    |Description              |
|--------------|-------------------------|
|`get_user_info`|Get user info  |   
|`get_best_server` | Get best server |   
|`get_server_list`   | Get server list           | 
|`start_test`   | Begin speed test           |
|`get_test_results`   | Get test results           |

#### Login

Params:

|Parameter   |Type  |Description                  |Required|
|------------|------|-----------------------------|--------|
|`username`|string|Username|true    |
|`password`     |string|Password|true    |

If scan is still in progress when trying to get result data, then it will output `"message": "Scan in progress"`

#### Get User Info

URI: `POST` http://192.168.1.1/rpc/

Get information about the user.

Params:

|Parameter   |Type  |Description                  |Required|
|------------|------|-----------------------------|--------|
|`sid`|string|Session ID|true    |
|`speedtest`     |string|Where get results function is|true    |
|`get_user_info`      |string|Get data about the user   |true    |


#### Get Best Server

URI: `POST` http://192.168.1.1/rpc/

Finds the best server based on user location and user-server latency

Params:

|Parameter   |Type  |Description                  |Required|
|------------|------|-----------------------------|--------|
|`sid`|string|Session ID|true    |
|`speedtest`     |string|Where get results function is|true    |
|`get_best_server`      |string|Get best server info   |true    |


#### Get Server List

URI: `POST` http://192.168.1.1/rpc/

Finds the best server based on user location and user-server latency

Params:

|Parameter   |Type  |Description                  |Required|
|------------|------|-----------------------------|--------|
|`sid`|string|Session ID|true    |
|`speedtest`     |string|Where get results function is|true    |
|`get_server_list`      |string|Get best server info   |true    |
|`"country"`      |string|Input country name    |false    |


If no country is written, then it sends back full server list.



#### Start Network Speed Test

URI: `POST` http://192.168.1.1/rpc/

Begin Speed Test

Params:

|Parameter   |Type  |Description                  |Required|
|------------|------|-----------------------------|--------|
|`sid`|string|Session ID|true    |
|`netscan`     |string|Where get results function is|true    |
|`start_test`      |string|Start speed test    |true    |
|`"id"`      |string| Expects server id    |true    |

Get server ID from server list. For examples go to: https://documenter.getpostman.com/view/17755621/Uze1wQ3y

#### Get Test results

URI: `POST` http://192.168.1.1/rpc/

Get Results

Params:

|Parameter   |Type  |Description                  |Required|
|------------|------|-----------------------------|--------|
|`sid`|string|Session ID|true    |
|`netscan`     |string|Where get results function is|true    |
|`get_test_results`      |string|Get test results   |true    |



