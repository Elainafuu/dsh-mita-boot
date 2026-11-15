# DeepSeek 大肥鱼 · 米塔式启动（DSH 启动动画）

给 DeepSeek Harness（DSH）用的一个启动动画模板 + 一组本地补丁，让开场动画像《米塔》的菜单一样：

- 鲸鱼娘先在画面中间做动作，镜头推近并右移，落到菜单位置；
- 视频播完的那一帧直接交给聊天背景（同一帧、同一位置、同一裁切），不闪、不跳；
- 聊天界面随后 0.5 秒淡入；
- 背景是同一帧的静态图，用代码驱动的待机动画（呼吸、重心摆动、微转头、鼠标视差、打字低头）保持「活着」。

动画长度约 2.47 秒，素材来自 B 站 `BV1YN416DEEg`。

## 依赖

- DeepSeek Harness（桌面端或 web 端均可）
- [dsh-boot-suite](https://github.com/LeeRolling/dsh-boot-suite) **2.13.x**（补丁基于 2.13.21 生成）
- Windows PowerShell

## 安装

```powershell
# 在仓库根目录
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

脚本会做三件事：

1. 把 `template/` 复制到 `%USERPROFILE%\.dsh\startup-templates\deepseek-game-boot\`
2. 把 `%USERPROFILE%\.dsh\dsh-startup.json` 里的 `template` 指向这个模板、`act2` 留空、`transitionOut` 设为 `none`（其它键保留）
3. 给 dsh-boot-suite 打三个补丁（原文件备份为 `*.bak-mita`）：
   - `lib/splash.css`：时间线模板的背景改为纯黑，避免浅色主题下露白边
   - `lib/splash.js`：视频层支持 `variants`、片尾帧交给聊天背景、连续交接、代码驱动的待机动画、按舞台矩形对齐截图
   - `lib/host-startup.js`：读取配置时忽略 UTF-8 BOM

装完重启 DSH 即可。

## 卸载 / 恢复

```powershell
# 还原补丁
cd "$env:USERPROFILE\.dsh\profiles\desktop\node_modules\dsh-boot-suite\lib"
Get-ChildItem *.bak-mita | ForEach-Object { Copy-Item $_.FullName ($_.FullName -replace '\.bak-mita$','') -Force }
# 删模板
Remove-Item "$env:USERPROFILE\.dsh\startup-templates\deepseek-game-boot" -Recurse -Force
```

## 注意

- **补丁会随插件升级失效**。升级 dsh-boot-suite 后重跑 `install.ps1` 即可（脚本会先备份再打）。
- 模板里的 `template.json` 有几个自定义字段：`lastFrame`（片尾帧图片）、`noCurtain`（不加黑幕）、`stageFit`（取景方式）。没有补丁时插件会忽略它们，退回默认行为。
- 启动动画和聊天背景是同一帧，所以**不要**单独替换 `boot-last.jpg`，除非同时也换了 `boot-main.mp4`。

## 素材与许可

- 视频素材：B 站 `BV1YN416DEEg`《⚡️DeepSeek大肥鱼是一款游戏⚡️》，UP 主「这里叫艾兰德Ai_land」。
- 动作参考：《米塔》（MiSide）启动菜单（`BV1EhCgYyESh`、`BV1Vm421H7Pu`）。
- 代码与模板：MIT。视频素材版权归原作者，**仅供个人学习自用，请勿商用或二次分发**。

详见 [NOTICE.md](NOTICE.md)。
