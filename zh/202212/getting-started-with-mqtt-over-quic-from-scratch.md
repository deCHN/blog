## 前言

QUIC([RFC9000](https://datatracker.ietf.org/doc/html/rfc9000)) 是下一代互联网协议HTTP/3的底层传输协议。与TCP/TLS协议相比，它**为移动互联网提供了一个高效、灵活的传输层，减少了网络开销和信息传递延迟。**

EMQX 5.0是第一个将QUIC引入MQTT的创新产品。我们在支持客户和开发技术时发现，QUIC的特性完全适合物联网中的一些场景，因此我们尝试用QUIC取代MQTT的传输层，这就产生了MQTT over QUIC。

正如文章 [mqtt-over-quic](https://www.emqx.com/en/blog/mqtt-over-quic)，QUIC具有低网络开销和复用能力的特点，这使它在网络不稳定和连接频繁切换的物联网场景中具有很大优势。测试数据显示，基于QUIC的0 RTT/1 RTT重新连接/新建的能力，MQTT over QUIC可以有效地提高用户在信号弱和连接不稳定的点状网络中的使用体验。

作为世界知名的开源和开放标准组织OASIS的基础赞助商，EMQ积极支持MQTT over QUIC的标准化。一些客户已经尝试使用这个新功能，我们也收到了良好的反馈。这篇文章将帮助你开始探索EMQX 5.0中的MQTT Over QUIC功能。

## 启用MQTT的QUIC功能

从EMQX 5.0开始支持MQTT over QUIC。请在这里下载并安装最新版本的EMQX：

https://www.emqx.com/en/try?product=broker

这是一个实验性的功能。对于CentOS 6、macOS和Windows，你需要从源代码编译QUIC。
请在编译时设置 ```BUILD_WITH_QUIC=1```

MQTT over QUIC 默认是禁用的。你可以按照下面的步骤手动启用它。

1. 打开配置文件etc/emqx.conf，取消对 ```listeners.quic.default``` 块的注释（如果不存在则手动添加）:

   ```
   # etc/emqx.conf
   listeners.quic.default {
     enabled = true
     bind = "0.0.0.0:14567"
     max_connections = 1024000
     keyfile = "etc/certs/key.pem"
     certfile = "etc/certs/cert.pem"
   }
   ```

2. 该配置在UDP端口14567上启用QUIC监听器。成功保存后，重新启动EMQX以激活配置。 你也可以使用环境变量启用QUIC功能:

   ```
   EMQX_LISTENERS__QUIC__DEFAULT__keyfile="etc/certs/key.pem" \
   EMQX_LISTENERS__QUIC__DEFAULT__certfile="etc/certs/cert.pem" \
   EMQX_LISTENERS__QUIC__DEFAULT__ENABLED=true
   ```

3. 使用 emqx_ctl listeners 命令来查看QUIC监听器的状态。

   ```
   > emqx_ctl listeners
   quic:default
   listen_on       : :14567
   acceptors       : 16
   proxy_protocol : undefined
   running         : true
   ssl:default
   listen_on       : 0.0.0.0:8883
   acceptors       : 16
   proxy_protocol : false
   running         : true
   current_conn   : 0
   max_conns       : 512000
   ```

   你也可以使用Docker进行快速体验，通过环境变量设置UDP端口14567作为QUIC端口:

   ```
   docker run -d --name emqx \
   -p 1883:1883 -p 8083:8083 \
   -p 8084:8084 -p 8883:8883 \
   -p 18083:18083 \
   -p 14567:14567/udp \
   -e EMQX_LISTENERS__QUIC__DEFAULT__keyfile="etc/certs/key.pem" \
   -e EMQX_LISTENERS__QUIC__DEFAULT__certfile="etc/certs/cert.pem" \
   -e EMQX_LISTENERS__QUIC__DEFAULT__ENABLED=true \
   emqx/emqx:5.0.10
   ```

## 支持QUIC的MQTT的客户端和工具

QUIC上的MQTT客户端和工具并不像普通的MQTT客户端那样功能齐全。


在适合MQTT的场景基础上，我们计划提供多种语言的客户端，如C、Java、Python和Golang。这些客户端将按优先顺序开发，以便适当的场景，如嵌入式硬件，能够尽快从QUIC中受益。

### **可用的客户端 SDKs**

- [NanoSDK](https://github.com/nanomq/NanoSDK/): An MQTT SDK based on C, released by the NanoMQ team at EMQ. In addition to MQTT over QUIC, it also supports other protocols, such as WebSocket and nanomsg/SP.
- [NanoSDK-Python](https://github.com/wanghaEMQ/pynng-mqtt): The Python binding of NanoSDK.
- [NanoSDK-Java](https://github.com/nanomq/nanosdk-java): The Java JNA binding of NanoSDK.
- [emqtt](https://github.com/emqx/emqtt): A MQTT client library, developed in Erlang, supporting QUIC.

除了客户端库，EMQ在边缘计算产品 NanoMQ 中为 _MQTT over QUIC_ 提供桥接能力。NanoMQ 可以用来通过 QUIC 将数据从边缘连接到云端，这样 _MQTT over QUIC_ 就可以零编码使用。

### **问题和解决方案**

许多运营商对来自UDP的数据包有特定的网络规则，由于QUIC是基于UDP的，这可能导致无法连接到QUIC或丢包。

因此，MQTT over QUIC客户端的设计具有回退能力：你可以通过统一的API开发服务，而传输层可以根据网络情况实时改变。如果QUIC不可用，它会自动切换到TCP/TLS 1.2，以确保服务可以在不同的网络中正常使用。

## 使用 NanoSDK 连接 _MQTT over QUIC_

[NanoSDK](https://github.com/nanomq/NanoSDK/) 是基于MsQuic项目的。它是第一个用C语言开发的MQTT over QUIC的SDK，它与EMQX 5.0完全兼容。NanoSDK的主要特点包括：异步I/O，MQTT连接到QUIC流的映射，低延迟的0RTT握手，以及多核的并行处理。

![NanoSDK](https://assets.emqx.com/images/4b4205bb4c8400b41c76829fc8b2c617.png)

### NanoSDK examples

该API遵循了与之前类似的风格。你可以用一行代码在QUIC的基础上创建一个MQTT客户端。

```
## Create MQTT over Quic client with NanoSDK
nng_mqtt_quic_client_open(&socket, url);
```

示例代码请参考: [https://github.com/nanomq/NanoSDK/tree/main/demo/quic](https://github.com/nanomq/NanoSDK/tree/main/demo/quic).

编译完成后，你就可以运行下面的命令，连接到14567端口进行测试:

```
quic_client sub/pub mqtt-quic://54.75.171.11:14567 topic msg
```

NanoSDK还提供Java绑定和Python绑定。有关例子请参考: [MqttQuicClient.java](https://github.com/nanomq/nanosdk-java/blob/main/demo/src/main/java/io/sisu/nng/demo/quicmqtt/MqttQuicClient.java) and [mqttsub.py](https://github.com/wanghaEMQ/pynng-mqtt/blob/master/examples/mqttsub.py).

## Bridge MQTT 3.1.1/5.0 and MQTT over QUIC via NanoMQ

[NanoMQ](https://nanomq.io/) 是一个超轻量级、高性能、跨平台的物联网边缘MQTT代理。它可以作为许多协议的消息总线，并且可以在MQTT和MQTT over QUIC之间建立桥梁。它通过QUIC协议转发MQTT数据包，这些数据包被发送到云上的EMQX。因此，那些不能用MQTT over QUIC SDK集成的边缘设备，或者找不到合适的MQTT over QUIC SDK的边缘设备，以及那些不能修改固件的嵌入式设备，都可以在物联网场景中利用QUIC协议。这对用户来说将是非常方便的。

![NanoMQ](https://assets.emqx.com/images/29f87fcca9842bc1ffc22422178c6ca6.png)

由于NanoMQ具有处理许多协议的能力，它在物联网场景中非常有用，因为数据要与云服务同步。它可以作为常见的经纪人/无经纪人消息传输协议的消息总线和存储系统，如HTTP、MQTT 3.1.1/5.0、WebSocket、nanomsg/nng和ZeroMQ。NanoMQ的 "actor"，一个强大的内置的消息处理模型，将这些协议的数据转换为MQTT协议的标准消息，并通过QUIC发送到云端。

这充分使用了MQTT over QUIC的能力，如0RTT快速重连和被动地址切换，以解决物联网连接中的常见问题，如网络漫游、网络的弱传输和TCP的线头阻塞。你还可以通过NanoMQ的规则引擎重定向、缓存或持久化数据。

基于EMQX+NanoMQ的云边缘消息架构，用户可以在泛物联网场景中随时随地快速、廉价地收集和同步数据。

值得一提的是，当QUIC连接失败时，NanoMQ可以自动切换到标准的MQTT over TCP/TLS，以确保你的设备不受网络环境影响。

### NanoMQ bridging example

Download and install NanoMQ:

```
git clone https://github.com/emqx/nanomq.git
cd nanomq ; git submodule update --init --recursive

mkdir build && cd build
cmake -G Ninja -DNNG_ENABLE_QUIC=ON ..
sudo ninja install
```

在编译和安装启用了QUIC的NanoMQ后，你可以在配置文件/etc/nanomq.conf中配置MQTT over QUIC和相关主题。使用mqtt-quic作为URL前缀意味着使用QUIC作为MQTT的传输层。

```
## Bridge address: host:port .
##
## Value: String
## Example: ## Example: mqtt-tcp://broker.emqx.io:1883 (This is standard MQTT over TCP)
bridge.mqtt.emqx.address=mqtt-quic://54.75.171.11:14567
```

### MQTT over QUIC CLI tools

NanoMQ还提供nanomq_cli，它包含MQTT over QUIC的客户端工具，供用户测试EMQX 5.0的MQTT over QUIC:

```
nanomq_cli quic --help
Usage: quic conn <url>
       quic sub  <url> <qos> <topic>
       quic pub  <url> <qos> <topic> <data>

## subscribe example
nanomq_cli quic sub mqtt-quic://54.75.171.11:14567 2 msg
```

#### 总之，你可以将NanoSDK直接集成到你的项目中，或者使用客户端工具，这两种工具都能够通过QUIC将设备连接到云端。

## 使用emqtt-bench 进行QUIC的性能测试

[emqtt-bench](https://github.com/emqx/emqtt-bench) 是一个用于MQTT性能测试的基准工具，它支持QUIC。我们用它来进行性能测试[MQTT over QUIC vs TCP/TLS]（https://www.emqx.com/en/blog/mqtt-over-quic#quic-vs-tcp-tls-测试对比）。它可以用来对应用程序进行基准测试，或者验证MQTT over QUIC在现实世界中的性能和优势。

### 编译 emqtt-bench

编译需要Erlang。以macOS为例，要安装Erlang和Coreutils。

```
brew install coreutils
brew install erlang@24
```

从源码编译 emqtt-bench:

```
git clone https://github.com/emqx/emqtt-bench.git
cd emqtt-bench
CMAKE_BUILD_TYPE=Debug BUILD_WITH_QUIC=1 make
```

编译成功后会显示以下提示:

```
...
===> Warnings generating release:
*WARNING* Missing application sasl. Can not upgrade with this release
===> Release successfully assembled: _build/emqtt_bench/rel/emqtt_bench
===> Building release tarball emqtt_bench-0.3+build.193.ref249f7f8.tar.gz...
===> Tarball successfully created: _build/emqtt_bench/rel/emqtt_bench/emqtt_bench-0.3+build.193.ref249f7f8.tar.gz
```

> 可能会出现以下错误，可以忽略不计:

```
/Users/patilso/emqtt-bench/scripts/rename-package.sh: line 9: gsed: command not found
/Users/patilso/emqtt-bench/scripts/rename-package.sh: line 9: gsed: command not found
/Users/patilso/emqtt-bench/scripts/rename-package.sh: line 9: gsed: command not found
/Users/patilso/emqtt-bench/scripts/rename-package.sh: line 9: gsed: command not found
```

### Test QUIC

转到编译的输出目录:

```
cd _build/emqtt_bench/rel/emqtt_bench/bin
```

你可以通过选项--quic使用QUIC来启动连接和订阅，这里有10个客户订阅主题```t/1```。

```
./emqtt_bench sub -p 14567 --quic -t t/1 -c 10
```

打开一个新窗口，同时使用QUIC连接并测试发布:

```
./emqtt_bench pub -p 14567 --quic -t t/1 -c 1
```

针对 "1 pub 10 sub" 的性能测试：

![performance test](https://assets.emqx.com/images/798b7d952bbc2cfa23bfbfe90e46449f.png)

检查本地UDP端口14567的使用情况:

```
$ lsof -nP -iUDP | grep 14567

com.docke 29372 emqx   76u  IPv6 0xea2092701c033ba9      0t0  UDP *:14567
beam.smp  50496 emqx   39u  IPv6 0xea2092701c014eb9      0t0  UDP [::1]:52335->[::1]:14567
beam.smp  50496 emqx   40u  IPv6 0xea2092701c017689      0t0  UDP [::1]:56709->[::1]:14567
beam.smp  50496 emqx   41u  IPv6 0xea2092701c0151c9      0t0  UDP [::1]:52175->[::1]:14567
beam.smp  50496 emqx   42u  IPv6 0xea2092701c0157e9      0t0  UDP [::1]:54050->[::1]:14567
beam.smp  50496 emqx   43u  IPv6 0xea2092701c015af9      0t0  UDP [::1]:58548->[::1]:14567
beam.smp  50496 emqx   44u  IPv6 0xea2092701c013639      0t0  UDP [::1]:52819->[::1]:14567
beam.smp  50496 emqx   45u  IPv6 0xea2092701c016119      0t0  UDP [::1]:57351->[::1]:14567
beam.smp  50496 emqx   46u  IPv6 0xea2092701c017999      0t0  UDP [::1]:52353->[::1]:14567
beam.smp  50496 emqx   47u  IPv6 0xea2092701c017ca9      0t0  UDP [::1]:57640->[::1]:14567
beam.smp  50496 emqx   48u  IPv6 0xea2092701c014ba9      0t0  UDP [::1]:55992->[::1]:14567
beam.smp  51015 emqx   39u  IPv6 0xea2092701c017069      0t0  UDP [::1]:64686->[::1]:14567
```

要了解更多关于emqtt-bench的信息，请参考帮助:

```
./emqtt_bench pub –help

./emqtt_bench conn –help

./emqtt_bench --help
```

## 总结

这是对MQTT over QUIC的初步了解。正如你所看到的，客户端库和EMQX能够在API层面和管理层面实现与MQTT相同的体验。只需替换传输层就能充分利用QUIC的特性，这给开发者带来了极大的便利，也促成了MQTT over QUIC的普及。此外，NanoMQ对MQTT over QUIC桥接的支持也提供了另一种灵活的解决方案。

随着MQTT over QUIC在现实世界中的广泛使用，用户还可以体验到先进的功能，如拥堵控制、连接的平滑迁移、端到端加密和低延迟握手。
