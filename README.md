# grafana Loki 日志采集系统学习
Loki 是受 Prometheus 启发的水平可扩展，高度可用的多租户日志聚合系统。它的设计具有很高的成本效益，并且易于操作。它不索引日志的内容，而是为每个日志流设置一组标签。

## 日志对比
ELK stack和Graylog，ELK目前很多公司都在使用，是一种很不错的分布式日志解决方案，但是需要的组件多，部署和维护相对复杂，并且占用服务器资源多。底层存储是es导致占用服务器资源过多

Loki vs ELK
- Loki 和 ELK（Elasticsearch, Logstash, Kibana）都是常用的日志处理系统，它们各自具有一些优点。下面是 Loki 相对于 ELK 的几个优点：
- 存储效率更高：Loki 使用了压缩和切割日志数据的方法来减少存储空间的占用，相比之下，ELK 需要维护一个大的索引，需要更多的存储空间。
- 查询速度更快：Loki 使用类似 Prometheus 的标签索引机制存储和查询日志数据，这使得它能够快速地进行分布式查询和聚合，而不需要将所有数据都从存储中加载到内存中。而ELK需要将数据从存储中加载到内存中进行查询，查询速度相对较慢。
- 部署和管理更容易：Loki 是一个轻量级的日志聚合系统，相比之下，ELK 需要部署和管理多个组件，需要更多的资源和人力成本。

## 优势
与其他日志聚合系统相比，Loki 有以下特点：
● 不对日志进行全文本索引。通过存储压缩的，非结构化的日志以及仅索引元数据，Loki 更加易于操作且运行成本更低。
● 使用与 Prometheus 相同的标签对日志流进行索引和分组，从而使您能够使用与 Prometheus 相同的标签在指标和日志之间无缝切换。
● 特别适合存储 Kubernetes Pod 日志。诸如 Pod 标签之类的元数据会自动被抓取并建立索引。
● 在 Grafana 中具有本机支持（需要 Grafana v6.0）。


## Loki 配置
```
auth_enabled: false

server:
  http_listen_port: 3100 # 配置HTTP监听端口号为3100。
  graceful_shutdown_timeout: 60s # 配置优雅停机的超时时间为60秒。
  http_server_read_timeout: 60s # 配置HTTP服务器读取超时时间为60秒。
  http_server_write_timeout: 60s # 配置HTTP服务器写入超时时间为60秒。


ingester: # 配置Loki的ingester部分，用于接收和处理日志数据。
  lifecycler: # 配置生命周期管理器，用于管理日志数据的生命周期。
    address: 127.0.0.1 # 配置生命周期管理器的地址
    ring:  # 配置哈希环，用于将日志数据分配给不同的Loki节点
      kvstore:  # 配置键值存储，用于存储哈希环的节点信息。 支持consul、etcd或者memroy,三者选其一
        store: inmemory  # 配置存储引擎为inmemory，即内存中存储
      replication_factor: 1  # 配置复制因子为1，即每个节点只存储一份数据。
    final_sleep: 0s # 配置最终休眠时间为0秒，即关闭时立即停止。
  chunk_idle_period: 1h       # 配置日志块的空闲时间为1小时。如果一个日志块在这段时间内没有收到新的日志数据，则会被刷新。
  max_chunk_age: 1h          # 配置日志块的最大年龄为1小时。当一个日志块达到这个年龄时，所有的日志数据都会被刷新。
  chunk_target_size: 1048576  # 配置日志块的目标大小为2048576字节（约为1.5MB）。如果日志块的空闲时间或最大年龄先达到，Loki会首先尝试将日志块刷新到目标大小。
  chunk_retain_period: 30s    # 配置日志块的保留时间为30秒。这个时间必须大于索引读取缓存的TTL（默认为5分钟）。
  max_transfer_retries: 0     # 配置日志块传输的最大重试次数为0，即禁用日志块传输。
  wal:
    enabled: true
    dir: /loki/wal

schema_config:  # 配置Loki的schema部分，用于管理索引和存储引擎。
  configs: # 配置索引和存储引擎的信息。
    - from: 2023-05-01  # 配置索引和存储引擎的起始时间。
      store: boltdb-shipper # 配置存储引擎为boltdb-shipper，即使用BoltDB存储引擎。
      object_store: filesystem # 配置对象存储引擎为filesystem，即使用文件系统存储。
      schema: v11 # 配置schema版本号为v11。
      index: # 配置索引相关的信息。
        prefix: index_  # 配置索引文件的前缀为index_。
        period: 24h  # 配置索引文件的周期为24小时。

storage_config: # 配置Loki的存储引擎相关的信息。
  boltdb_shipper:  # 配置BoltDB存储引擎的信息。
    active_index_directory: /loki/boltdb-shipper-active # 配置活动索引文件的存储目录为/tmp/loki/boltdb-shipper-active。
    cache_location: /loki/boltdb-shipper-cache  # 配置BoltDB缓存文件的存储目录为/tmp/loki/boltdb-shipper-cache。
    cache_ttl: 240h        # 配置BoltDB缓存的TTL为240小时。
    shared_store: filesystem # 配置共享存储引擎为filesystem，即使用文件系统存储。
  filesystem: # 配置文件系统存储引擎的信息，即日志数据的存储目录为/tmp/loki/chunks
    directory: /loki/chunks

compactor: # 配置日志压缩器的信息。
  working_directory: /loki/boltdb-shipper-compactor # 配置工作目录为/tmp/loki/boltdb-shipper-compactor。
  shared_store: filesystem  #配置共享存储引擎为filesystem，即使用文件系统存储
limits_config: # 配置Loki的限制策略。
  reject_old_samples: true  # 配置是否拒绝旧的日志数据。
  reject_old_samples_max_age: 168h  # 配置拒绝旧的日志数据的最大年龄为168小时。
  ingestion_rate_mb: 64 # 配置日志数据的最大摄入速率为64MB/s。
  ingestion_burst_size_mb: 128 # 配置日志数据的最大摄入突发大小为128MB。
  max_streams_matchers_per_query: 100000 # 配置每个查询的最大流匹配器数量为100000。
  max_entries_limit_per_query: 50000 # 配置每个查询的最大条目限制为50000。


chunk_store_config:  # 配置日志数据的存储策略。
  max_look_back_period: 0s # 配置最大回溯时间为240小时。

table_manager:  # 配置Loki的表管理器。
  retention_deletes_enabled: false  # 配置是否启用保留期删除。
    # retention_period: 240h # 配置保留期为240小时。
  retention_period: 0s

ruler:
  storage:
    type: local
    local:
      directory: /loki/rules
  rule_path: /loki/rules-temp
  alertmanager_url: http://localhost:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true

```

## promtail 配置

```

#  配置 promtail 程序运行时行为。如指定监听的ip、port等信息。
server:
  http_listen_port: 9080
  grpc_listen_port: 0
# positions 文件用于记录 Promtail 发现的目标。该字段用于定义如何保存 postitions.yaml 文件
# Promtail 发现的目标就是指日志文件。
positions:
  filename: /etc/promtail/positions.yaml   # 游标记录上一次同步位置
  sync_period: 10s #10秒钟同步一次
# 配置 Promtail 如何连接到 Loki 的多个实例，并向每个实例发送日志。
# Note：如果其中一台远程Loki服务器无法响应或发生任何可重试的错误，这将影响将日志发送到任何其他已配置的远程Loki服务器。
# 发送是在单个线程上完成的！ 如果要发送到多个远程Loki实例，通常建议并行运行多个Promtail客户端。
clients:
  - url: http://loki:3100/api/prom/push
# 配置 Promtail 如何发现日志文件，以及如何从这些日志文件抓取日志。
scrape_configs:  # 指定要抓取日志的目标。
- job_name: http-log  
  pipeline_stages: 
    - regex:
        expression: "^(?P<time>(\\d{4}-\\d{2}-\\d{2})\\s(\\d{2}:\\d{2}:\\d{2})) (?P<logtype>(\\[(.+?)\\])) (?P<appname>(\\[(.+?)\\])) (?P<requesttype>(\\[(.+?)\\])) (?P<tid>(\\[(.+?)\\])) (?P<cid>(\\[(.+?)\\])) (?P<traceid>(\\[(.+?)\\])) (?P<spanid>(\\[(.+?)\\])) (?P<parentid>(\\[(.+?)\\])) (?P<trace>(trace\\[(.+?)\\])) (?P<data>(.*)) (?P<logcate>(.*))"
    - labels:
        logtype:
        logcate:
    - timestamp:
        source: time
        format: RFC3339Nano
  static_configs:
  - targets:
      - localhost # 指定抓取目标，i.e.抓取哪台设备上的文件
    labels: # 指定该日志流的标签
      job: http-log 
      __path__: /var/logs/http/*.log  # 指定抓取路径，该匹配标识抓取 /var/log/host 目录下的所有文件。注意：不包含子目录下的文件
```
## regex 调试技巧
使用 regex 匹配时,可以使用 [https://regex101.com/](https://regex101.com/r/DKqRpL/1) 进行调试

TIPS:
- Flavor 选择 GOLANG
- Function 选择 Match
- Match Information 可以查看你的匹配结果
![image.png](/img/bVc76i1)



## Loki 选择器
点击 “Log browser” ，可以快速浏览采集上来的label信息
![image.png](/img/bVc76jb)

查询表达式

对于查询表达式的标签部分，将其包装在花括号中{}
使用键值对的语法来选择标签
多个标签表达式用逗号分隔

全文匹配一个关键词abc的日志，可以这样写
```
{filename="/var/log/operation.LOG"} |="abc"
```

目前支持以下标签匹配运算符：

= 等于
!= 不等于
=~ 正则匹配
!~ 正则不匹配
## 部署



## 参考资料
- [Grafana Loki初体验](https://zhuanlan.zhihu.com/p/517431546)
- [Promtail Pipeline 日志处理配置](https://www.modb.pro/db/618328)
- [Grafana Loki官网翻译-个人学习笔记](https://zhuanlan.zhihu.com/p/621432370)
- [Docker(14) docker-compose安装Grafana Loki日志聚合系统](https://blog.csdn.net/qq_38225558/article/details/107524340)
- [grafana Loki 轻量级日志收集系统](https://blog.csdn.net/weixin_44316575/article/details/121676736)
- [Loki+Grafana查询语句](https://blog.csdn.net/zjcjava/article/details/126178551)
- [Grafana Explore 中的日志](https://zhuanlan.zhihu.com/p/603066874)
