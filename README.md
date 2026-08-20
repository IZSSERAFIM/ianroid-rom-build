# ianroid-rom-build

为一台 **MT6737T 山寨 iPhone 克隆机**（`ios6737t_36_a_n`，ODM「cenon」，基于 MTK 公版 `bd6737t_36_a_n`）构建 TWRP 与后续 ROM。全部通过 GitHub Actions 编译。

## 设备实测参数

| 项目 | 值 | 来源 |
|---|---|---|
| SoC | MT6737T（Cortex-A53 ×4 @1.5GHz，Mali-T720 MP2） | `ro.mediatek.platform` |
| 内核 | `3.18.35+ (zxl@zxl) gcc 4.8`，2019-01-16 | `/proc/version` |
| 架构 | **32 位**（`ro.product.cpu.abilist64` 为空） | `getprop` |
| 系统 | Android 7.0 / NRD90M，补丁停在 2017-05-05 | `getprop` |
| 内存 | **实际约 1.89GB**（`/proc/meminfo` 被内核改成谎报 4.8GB） | `/proc/zoneinfo` present pages |
| 存储 | 金士顿 eMMC 16GB（14.58 GiB） | `/sys/block/mmcblk0/size` |
| 屏幕 | 720×1498，density 320，`st7703_hd720_dsi_vdo_lcm` | `wm size` / `tpd_info` |
| 触摸 | Goodix `gt1x` | `/proc/driver/tpd_info` |
| 摄像头 | 后 S5K3H2YX / 前 OV5670 | `tpd_info` |
| Treble | **无 vendor 分区** | by-name 分区表 |

## boot image 几何（取自 stock recovery header）

```
base    = 0x40000000    kernel  = 0x40008000
ramdisk = 0x44000000    tags    = 0x4E000000
pagesize = 2048         cmdline = bootopt=64S3,32N2,32N2
```

boot 与 recovery 使用**同一个内核**（sha256 一致）。

## 为什么用 prebuilt 内核

厂商从未公开内核源码（编译者是 `zxl@zxl`，私人机器构建，属 GPL 违规）。
因此 `device/kernel` 直接取自本机 stock recovery 分区 —— 它含有本机专属的
`st7703` 屏驱动与 `gt1x` 触摸驱动，是同芯片其他机型的内核所不具备的。

实测佐证：一份 Unihertz Jelly Pro 的 TWRP（ARM64 + 无 st7703/gt1x）刷入必然黑屏；
换用本机内核 + 32 位 ramdisk 后显示与触摸均正常。

## 为什么需要 `TW_ROTATION := 180`

本机屏幕**物理倒装**。原厂系统靠 `build.prop` 里的 `ro.sf.hwrotation=180`
在 SurfaceFlinger 层补偿；TWRP 直接写 framebuffer，不读该属性，故画面上下颠倒。

已排除的运行时解法：`/sys/class/graphics/fb0/rotate` 节点存在，写入 `180` 能被接受
（写 `2` 被拒），但 MTK 驱动并未真正执行旋转，实测画面无变化。故只能在编译期修正。

## 用法

Actions → *Build TWRP (ios6737t / MT6737T)* → Run workflow，产物在 artifact 里。

刷入前**务必先试运行，不要直接写入分区**：

```bash
fastboot boot recovery.img          # 仅加载到内存，不写 eMMC
# 确认显示方向与触摸都正常后，再考虑：
fastboot flash recovery recovery.img
```

本机 LK 已实测支持完整 fastboot 命令集（`flash / erase / boot / download / getvar / oem unlock`），
且 `fastboot getvar unlocked` 返回 `yes`。

## 致谢

设备树结构参考 [seluce/android_twrp_device](https://github.com/seluce/android_twrp_device)
（Cubot Note Plus，同为 MT6737T + kernel 3.18.35，boot 参数与本机逐项吻合）。
