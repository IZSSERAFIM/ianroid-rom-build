#!/usr/bin/env bash
#
# 把 seluce 的 Cubot X18 LineageOS 14.1 设备树适配到本机 ios6737t。
#
# 设计取舍：不 fork 整棵树，而是在 CI 里克隆上游后打一层薄覆盖。
# 这样上游修 bug 我们能直接受益，我们自己的改动也一目了然。
#
# 用法: apply-overrides.sh <lineage 源码根目录> <本仓库根目录>
set -euo pipefail

SRC="${1:?需要 lineage 源码根目录}"
OWN="${2:?需要本仓库根目录}"
DEV="$SRC/device/CUBOT/X18"

# 是否把电话配置也改成本机的。默认关闭 ——
# 本机是国行双基带(MD1 + MD3/C2K)单待单 IMEI，X18 是欧版单基带无 CDMA。
# 但 X18 的 blobs 里只有 modem_1_lwg_n.img(LTE/WCDMA/GSM，无 C2K)，
# 此时若把 opt_md3_support 打开却没有对应固件，RIL 可能崩溃循环，
# 反而干扰"能否开机"的判断。等换成本机 blobs 时再置 1。
APPLY_TELEPHONY="${APPLY_TELEPHONY:-0}"

say() { printf '  %-46s %s\n' "$1" "$2"; }
echo "=== 适配 X18 设备树 -> ios6737t ==="

# ---------------------------------------------------------------- 内核
# 厂商从未公开内核源码，只能用从本机 recovery 分区抽出的 prebuilt。
# 它含本机专属的 st7703 屏驱动与 gt1x 触摸驱动，是 X18 内核不具备的。
cp -f "$OWN/device/kernel" "$DEV/kernel"
say "kernel" "已替换为本机 prebuilt ($(stat -c%s "$DEV/kernel") bytes)"

# ---------------------------------------------------------------- 显示
# 本机屏幕物理倒装，原厂靠 ro.sf.hwrotation=180 在 SurfaceFlinger 层补偿。
sed -i 's/^ro\.sf\.hwrotation=.*/ro.sf.hwrotation=180/' "$DEV/system.prop"
say "ro.sf.hwrotation" "0 -> 180 (物理倒装屏)"

# density 两边都是 320，无需改动 —— 这也是选 X18 而非 Note Plus 的原因
grep -q '^ro\.sf\.lcd_density=320' "$DEV/system.prop" \
  && say "ro.sf.lcd_density" "320，与本机一致，保持不变"

sed -i 's#^persist\.sys\.timezone=.*#persist.sys.timezone=Asia/Shanghai#' "$DEV/system.prop"
say "时区" "Europe/Berlin -> Asia/Shanghai"

# 分辨率：X18 是 720x1440，本机 720x1498
sed -i 's/^TARGET_SCREEN_HEIGHT :=.*/TARGET_SCREEN_HEIGHT := 1498/' "$DEV/lineage.mk"
sed -i 's/^DEVICE_RESOLUTION :=.*/DEVICE_RESOLUTION := 720x1498/' "$DEV/lineage.mk"
say "分辨率" "720x1440 -> 720x1498"

# ---------------------------------------------------------------- 分区
# 本机 system 分区(p20)比 X18 大，用本机实测值，否则会浪费可用空间
sed -i 's/^BOARD_SYSTEMIMAGE_PARTITION_SIZE :=.*/BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2625634304/' \
  "$DEV/BoardConfig.mk"
say "system 分区" "2432696320 -> 2625634304 (本机 p20 实测)"

# 刷机 zip 的 updater-script 会断言机型，不加本机名字会拒刷
sed -i 's/^TARGET_OTA_ASSERT_DEVICE :=.*/TARGET_OTA_ASSERT_DEVICE := CUBOT_X18,X18,iPhone,ios6737t/' \
  "$DEV/BoardConfig.mk"
say "OTA assert" "追加 iPhone,ios6737t (本机 ro.product.device=iPhone)"

# ---------------------------------------------------------------- 分区表
# 用本机实测 by-name 映射，已在 TWRP 里验证过能正确挂载全部分区
cp -f "$OWN/device/recovery.fstab" "$DEV/rootdir/recovery.fstab"
say "recovery.fstab" "已替换为本机实测分区表"

# ---------------------------------------------------------------- 电话
if [ "$APPLY_TELEPHONY" = "1" ]; then
    P="$DEV/system.prop"
    sed -i 's/^persist\.radio\.multisim\.config=.*/persist.radio.multisim.config=ss/' "$P"
    sed -i 's#^ro\.mtk_protocol1_rat_config=.*#ro.mtk_protocol1_rat_config=C/Lf/Lt/W/T/G#' "$P"
    sed -i 's/^ro\.boot\.opt_md3_support=.*/ro.boot.opt_md3_support=2/' "$P"
    sed -i 's/^ro\.boot\.opt_c2k_lte_mode=.*/ro.boot.opt_c2k_lte_mode=1/' "$P"
    sed -i 's/^ro\.mtk_md_sbp_custom_value=.*/ro.mtk_md_sbp_custom_value=1/' "$P"
    sed -i '/^ro\.longcheer\.sku=/d' "$P"
    cat >> "$P" <<'EOF'

# --- 本机(国行双基带)电话配置 ---
ro.mtk_c2k_support=1
ro.mtk_enable_md3=1
ro.mtk_single_imei=1
ro.telephony.default_network=10,10
EOF
    say "电话配置" "已改为本机国行双基带 (C2K/MD3 启用)"
else
    say "电话配置" "保持 X18 原样 (APPLY_TELEPHONY=0)"
fi

echo
echo "=== 关键差异确认 ==="
grep -E '^(ro\.sf\.hwrotation|ro\.sf\.lcd_density|persist\.sys\.timezone|persist\.radio\.multisim\.config)=' \
  "$DEV/system.prop" | sed 's/^/  /'
grep -E '^(BOARD_SYSTEMIMAGE_PARTITION_SIZE|TARGET_OTA_ASSERT_DEVICE|TARGET_PREBUILT_KERNEL)' \
  "$DEV/BoardConfig.mk" | sed 's/^/  /'
grep -E '^(TARGET_SCREEN_HEIGHT|DEVICE_RESOLUTION)' "$DEV/lineage.mk" | sed 's/^/  /'
