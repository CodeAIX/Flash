# Flash

Flash 是基于 [FlClash](https://github.com/chen08209/FlClash) 的非官方衍生客户端，由 CodeAIX 维护。保留 FlClash 的代理内核、配置、订阅、规则、节点与原有交互，新增 macOS 状态栏可视化。Flash 不提供代理节点或订阅服务。

## 下载

从 [Flash Releases](https://github.com/CodeAIX/Flash/releases/latest) 下载 macOS 安装包：

- `arm64`：Apple Silicon（M 系列）。
- `x86_64`：Intel Mac。

打开 DMG，将 Flash 拖入 Applications。安装包采用 ad-hoc 签名，尚未经过 Apple 公证。每个版本附 SHA-256 校验、准确源码及内核子模块源码。

## Flash 特性

状态图标采用圆角矩形，内嵌当前规则出口的 IP 国家代码。

| 图标 | 含义 |
| --- | --- |
| 绿色底色 | TUN 已配置开启，优先于系统代理状态 |
| 蓝色底色 | TUN 关闭、系统代理已配置开启 |
| 橙色底色 | TUN 与系统代理均未配置开启 |
| 白色国家代码 | 当前 IP 的 FlClash 内嵌质量评级为“优秀” |
| 黑色国家代码 | 其他评级，或质量未知、查询中、查询失败 |
| 灰底原版风格符号 | 代理停止或暂停 |
| 中性底红色 F | 出口查询异常 |

未知国家显示 `--`。底色表示入口配置，字色表示 IP 质量；均不等于所有应用、规则或 AI 服务的连通性保证。国家代码只描述该次规则出口查询。

Flash 复用 FlClash 内核、出口与 IP 质量检测，不增加第二个代理内核。运行期间保持后台状态监测，定期刷新；切换出口后不会沿用前一个 IP 的质量结果。保留原有托盘菜单、节点操作与速度显示。

目前仅分发 macOS 版本。Windows 与 Android 的 Flash 品牌和状态显示适配尚未完成。

## 与 FlClash 的关系及版本

Flash 不是 FlClash 官方发行版。上游功能、核心实现及主要界面归功于 FlClash、mihomo 和各第三方项目；原版权和 [GPL-3.0 许可证](LICENSE) 保留，修改说明见 [FLASH-NOTICE.md](FLASH-NOTICE.md)。

Flash 版本按上游正式版的 major 加 1，minor、patch 保持一致：`0.9.1 → 1.9.1`、`0.9.2 → 1.9.2`、`0.10.0 → 1.10.0`。这不是 SemVer 的 `+` 构建元数据语法。对应上游版本、commit 与 Flash 版本记录在 [flash/upstream.json](flash/upstream.json)。

## 独立定制与自动更新

Flash 定制以 [flash/runtime.patch](flash/runtime.patch) 和文件清单维护，文档、品牌声明及工作流作为覆盖文件保留。更新器每天检查上游正式 Release，排除预发布；从固定 tag 重建源码并尝试应用定制补丁。

补丁冲突即停止，不丢弃 Flash 改动。兼容时创建候选分支和 PR，显式触发检查、测试及 macOS 双架构构建；全部通过才合并并发布对应版本。构建成功不代替网络行为的人工验收。上游若修改托盘、provider、平台身份或工具链，仍可能需要人工适配。

## 从源码构建

使用源码包内固定版本的 Flutter、Go、Rust 要求；本次基线为 Flutter 3.47.6、Go 1.27、Rust 1.99.0，以及 Xcode 26 SDK 或兼容更新版本。

```sh
git clone --recursive https://github.com/CodeAIX/Flash.git
cd Flash
flutter pub get
flutter build macos --release --dart-define=FLASH_STATUS_ICON=true
```

本地调试请使用 `--dart-define=SAFE_MODE=true`，以免接管现有代理环境。使用 `--dart-define=FLASH_STATUS_ICON=false` 可回退原版模板托盘图标。
