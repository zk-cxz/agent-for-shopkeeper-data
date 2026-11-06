# 本地运行说明（无 Docker 版）

本机没有 Docker，且 WSL 被安全策略禁用，因此没有按 README 使用 `docker compose`，
而是把四个依赖服务改成 Windows 原生方式运行。功能与 README 描述的一致，只是组件来源不同。

## 一、实际使用的组件

| 组件 | README 方案 | 本机实际方案 | 地址 |
| --- | --- | --- | --- |
| MySQL | Docker `mysql:8.0` | 复用本机已安装的 MySQL **5.7**（新库 `meta`、`dw`，用户 `didilili`） | `127.0.0.1:3306` |
| Elasticsearch | Docker `8.19.10` + IK 插件 | Windows 原生 **8.9.2**（华为云镜像），取值索引改用内置 `cjk` 分词 | `127.0.0.1:9200` |
| Qdrant | Docker `qdrant:v1.16` | `qdrant-client` **本地嵌入模式**（数据落盘，无独立进程） | `D:/dev-tools/qdrant-storage` |
| Embedding | Docker TEI `cpu-1.8` | `sentence-transformers` 加载同一份 `bge-large-zh-v1.5`，对外提供 TEI 兼容的 `/embed` | `127.0.0.1:8081` |
| Python | 3.14 | uv 独立安装的 **3.14.10**，不影响本机 3.10 | `.venv` |
| 前端 | pnpm | 同 README | `127.0.0.1:5173` |

## 二、日常启动

双击项目根目录的 `run-local.bat`，脚本会依次拉起 ES、Embedding、后端、前端。
不用的时候，关掉那四个独立窗口即可停服务；也可以双击 `stop-local.bat` 一次全停
（只按端口 9200/8081/8000/5173 结束进程，不会动 MySQL 57 服务，磁盘上的数据也都保留，
下次直接再 `run-local.bat` 即可）。保留停止脚本主要是为了避免漏关最小化窗口、
以及清理 `pnpm -> node`、ES `java` 启动器这类可能残留的孤儿进程，防止下次提示端口被占用。
这些服务不会自己退出，只要进程还在就一直占着内存。
或者手动开四个终端：

```bash
# 1. Elasticsearch
D:\dev-tools\es\elasticsearch-8.9.2\bin\elasticsearch.bat

# 2. Embedding 服务
D:\dev-tools\embedding-env\Scripts\python.exe D:\dev-tools\local-stack\embedding_server.py

# 3. 后端
.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000

# 4. 前端
cd frontend && pnpm dev
```

访问 <http://127.0.0.1:5173>，接口文档 <http://127.0.0.1:8000/docs>。

## 三、重建元数据知识库

重建前需要先停掉后端（Qdrant 本地模式是文件独占锁，两个进程不能同时打开同一份数据）。

```bash
.venv\Scripts\python.exe -m app.scripts.build_meta_knowledge -c conf/meta_config.yaml
```

## 四、相对原始仓库的改动

1. `app/clients/qdrant_client_manager.py`
   新增 `QDRANT_LOCAL_PATH` 环境变量分支：设置时走 qdrant-client 本地模式，未设置时仍按 URL 连接，
   Docker 方案下的行为不变。

2. `conf/app_config.yaml`
   - `llm` 三个字段改为支持环境变量覆盖（`LLM_MODEL` / `LLM_BASE_URL` / `LLM_API_KEY`），切换平台不用改代码。
   - 各服务 `host` 由 `localhost` 改为 `127.0.0.1`，避免 `localhost` 解析到 IPv6 导致连接失败。

3. `.env`
   写入大模型配置、`QDRANT_LOCAL_PATH`、以及 `NO_PROXY`（本机访问 8080/9200 等本地服务时绕开系统代理）。

4. 新增 `run-local.bat`：一键启动本地四个服务。

5. 索引 `value_index` 已预创建（`value` 字段使用 `cjk` 分词）。
   代码里 `ensure_index` 检测到索引已存在会直接跳过，因此无需修改 `value_es_repository.py`。
   如果删除该索引又没装 IK 插件，重建时会在 `ik_max_word` 处报错。

## 五、注意事项

- Elasticsearch 堆内存已设为 1g，见 `D:\dev-tools\es\elasticsearch-8.9.2\config\jvm.options.d\heap.options`。
- 模型权重在 `docker/embedding/bge-large-zh-v1.5`（约 1.2GB，仓库不提交）。
- 本机若要彻底恢复到 README 的 Docker 方案，装好 Docker Desktop 后 `docker compose -f docker/docker-compose.yaml up -d`，
  并删掉 `.env` 里的 `QDRANT_LOCAL_PATH` 即可，代码无需回滚。
