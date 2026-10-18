# AI CLI Kickstarter

给完全不懂计算机的人安装第一个 AI CLI，然后由这个 AI 接管后续指导。

## 支持

- Qwen Code
- Kimi Code
- CodeBuddy CLI
- Claude Code
- macOS
- Linux
- Windows
- 中文 / English

## 使用

### macOS

解压后双击 `Start-macOS.command`。若 macOS 阻止运行，右键文件并选择“打开”。

### Linux

打开终端，在本目录运行：

```bash
bash Start-Linux.sh
```

### Windows

双击 `Start-Windows.cmd`。它会启动 PowerShell 状态机。

若出现「Windows 已保护你的电脑」（SmartScreen）提示，点击「更多信息」，再点击「仍要运行」。这是 Windows 对从网上下载的文件的常规提醒。

### Claude Code（选项 4）

macOS / Linux / WSL 使用同一 Bash 状态机，Windows 使用 PowerShell 状态机；三个启动入口无需更改，默认仍为 Qwen Code。

- macOS、Linux、WSL：官方原生安装器 `https://claude.ai/install.sh`。
- Windows：官方原生安装器 `https://claude.ai/install.ps1`，无需管理员权限。Git for Windows 为可选依赖。
- 前置要求：macOS 13+、Windows 10 1809+ / Server 2019+，或官方支持的 Linux；x64 / ARM64、至少 4 GB 内存。具体发行版及 Alpine 额外依赖见官方文档。
- 验证：`claude --version`；验证失败进入 ERROR，不显示交接或启动提示。PATH 未刷新时请重开终端后验证。
- 安装成功不代表认证或服务可用。首次运行 `claude` 按提示认证；需要符合 Anthropic 服务地区和账户要求。启动器不收集或配置 API Key，也不配置第三方模型服务。
- 官方说明：https://code.claude.com/docs/en/setup （核对日期：2026-10-18）。

## Prompt 库：安装之后做什么

安装完成时，启动器会显示一段「交接 Prompt」，让 AI 检查电脑环境并建议下一步——那是第 0 个任务。下面是后续任务清单：每个 Prompt 对应一个完整任务（Mission），而不是一句泛泛的提问。

用法：每次开新会话，先粘贴「通用前置」，再粘贴一个任务 Prompt。

### 通用前置（每次新会话先粘贴）

```text
请把我当作计算机新手，始终用中文回复。
遇到我可能不懂的概念，先用通俗语言解释再继续。
动手改动之前：说明目标、说明风险、估计所需时间。
修改任何配置文件前先备份。
涉及管理员权限、删除、覆盖、付费或隐私的操作，先征得我的同意。
每完成一步都验证结果。
优先选择能解决问题的最简单方案；有多个好选项时只推荐最优的一个，并说明理由。
```

### 起步

**1. 初始化这台电脑**

```text
请帮我把这台电脑配置成适合现代 AI 开发的环境。
只安装必要的工具，例如：包管理器、终端增强、字体、Shell 提示符、常用命令行工具。
请根据我的操作系统选择最合适的工具。
```

**2. 打造 AI 工作站**

```text
请把这台电脑打造成以 AI 为核心的工作站。
针对编程、写作、研究、终端、浏览器、AI Agent 分别推荐最合适的工具。
逐项征得我同意后再安装。
```

### 体检与治理

**3. 全面体检**

```text
请对这台电脑做一次全面体检。
检查：硬件、操作系统、存储、内存、安全、备份、已安装软件、开发环境。
找出问题，先列出问题清单和修复方案，经我逐项确认后再修复。
```

**4. 终端环境审计**

```text
请检查我的终端环境。
优化：Shell、PATH、别名、提示符、字体、包管理器、开发工具。
清理过时的配置，保持整体简洁、易于维护。
```

**5. 软件治理**

```text
请审计这台电脑上安装的所有软件。
找出：重复的、过时的、不再需要的、相互冲突的软件。
告诉我哪些应该删除、更新或替换并说明理由，经我确认后执行。
```

**6. 存储清理**

```text
请分析这台电脑的存储使用情况。
找出：大文件、重复文件、不再需要的下载、临时文件。
给出清理方案。未经我确认不得删除任何文件；删除时优先使用可恢复的方式（如回收站）。
```

### 网络

**7. 局域网审计**

```text
请帮我检查这里的局域网。
识别网内设备：电脑、NAS、打印机、路由器、交换机、Wi-Fi。
只做只读探测，不要修改任何设备的配置。
找出性能、安全、易用性方面的问题，给出改进建议。
```

**8. 搭建跨地点私有网络**

```text
请帮我把多个地点的设备连成一个私有网络。
推荐最简单、最安全的架构，并比较可选方案。
我选定方案后，一步一步带我完成搭建。
```

### 进阶

**9. 自动化**

```text
请帮我找出可以自动化的重复性工作。
先问我平时经常手动做哪些事，再判断哪些值得自动化、哪些不值得。
只实现我批准的自动化，并解释每个自动化是如何工作的。
```

**10. 长期模式：我的 IT 工程师**

```text
从现在起，请作为我的私人 IT 工程师。
我提出需求时，选最简单可靠的方案；如果存在明显更好的做法，先说明理由再推荐。
帮助我逐步变得更懂电脑，但不要一次教太多。
```

## 状态机

`LANGUAGE → PROBE → SELECT → PRECHECK → CONFIRM → INSTALL → VERIFY → HANDOFF`

失败时进入 `ERROR`，用户可以重试、换工具或退出。

## 网络检测

启动器请求：

`https://www.google.com/generate_204`

它只判断当前 Terminal/PowerShell 是否能直接连接 Google，不推断用户所在地，也不推断其他国际服务是否可用。

## 安装来源

- Claude Code：Anthropic 官方 native installer，地址见上方平台说明
- Qwen Code：官方 standalone installer
- Kimi Code：官方 installer
- CodeBuddy CLI：官方 native installer（当前官方文档标注 Beta）

安装器会在执行前显示下载地址。供应商可能更新安装方式，因此发布前应重新核对官方文档。

信任模型：本工具会下载并执行上述四家官方域名提供的安装脚本，运行安装即表示信任这些来源。启动器不会自行校验脚本内容，但会在执行前显示下载地址并要求确认。

## 开发

- 运行测试：`bash tests/run-tests.sh`（使用本地 curl 桩，不访问网络）
- Lint：`shellcheck kickstarter.sh Start-Linux.sh Start-macOS.command`
- CI（GitHub Actions）在每次 push 时运行 shellcheck、PSScriptAnalyzer 与冒烟测试
- `kickstarter.sh` 与 `kickstarter.ps1` 互为镜像，修改状态或文案时需要同步两个文件

## 许可证

MIT，见 [LICENSE](LICENSE)。

