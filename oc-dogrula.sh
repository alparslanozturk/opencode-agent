#!/usr/bin/env bash
# =============================================================================
#  oc-dogrula.sh — bu paketin kurulumunu doğrular (İNTERNET GEREKTİRMEZ).
#  Kullanım:  ./oc-dogrula.sh
#  Çıkış kodu: 0 = paket sağlam (uyarılar olabilir)
#              1 = ciddi sorun (ikili yok, mimari uymuyor, JSON bozuk)
# =============================================================================
set -uo pipefail

# --- kendi gerçek konumunu bul (symlink zincirini çözer) ---
_kaynak="${BASH_SOURCE[0]}"
while [ -L "$_kaynak" ]; do
  _hedef="$(readlink "$_kaynak")"
  case "$_hedef" in
    /*) _kaynak="$_hedef" ;;
    *)  _kaynak="$(cd "$(dirname "$_kaynak")" && pwd)/$_hedef" ;;
  esac
done
KOK="$(cd "$(dirname "$_kaynak")" && pwd)"

yesil()   { printf '\033[32m%s\033[0m\n' "$*"; }
kirmizi() { printf '\033[31m%s\033[0m\n' "$*"; }
sari()    { printf '\033[33m%s\033[0m\n' "$*"; }

HATA=0
UYARI=0
ok()   { yesil   "  ✓ $*"; }
hata() { kirmizi "  ✗ $*"; HATA=$((HATA + 1)); }
uyar() { sari    "  ! $*"; UYARI=$((UYARI + 1)); }

BIN="$KOK/bin/opencode"

echo "== 1/6  ikili — varlık + ELF mimarisi + glibc uyumu (RHEL9+) =="
if [ ! -e "$BIN" ]; then
  hata "$BIN YOK"
else
  ok "$BIN var"
  bilgi="$(file -b "$BIN" 2>/dev/null || true)"
  case "$bilgi" in
    *"ELF 64-bit"*"x86-64"*) ok "ELF 64-bit x86-64" ;;
    *) hata "beklenmeyen ikili biçimi: $bilgi" ;;
  esac
  if command -v objdump >/dev/null 2>&1; then
    en_yuksek="$(objdump -T "$BIN" 2>/dev/null | grep -o 'GLIBC_[0-9.]*' | sort -V | tail -1)"
    if [ -n "$en_yuksek" ]; then
      ok "gerekli en yüksek glibc: $en_yuksek (RHEL9=2.34, RHEL10=2.39 → uyumlu)"
    else
      uyar "glibc sürüm bilgisi okunamadı (objdump çıktısı boş)"
    fi
  else
    uyar "objdump yok — glibc sürüm kontrolü atlandı"
  fi
fi

echo "== 2/6  opencode --version =="
if [ -x "$BIN" ]; then
  if v="$(timeout 30 "$BIN" --version 2>&1)"; then
    ok "opencode $v"
  else
    hata "opencode --version başarısız: $v"
  fi
else
  uyar "ikili çalıştırılabilir değil — sürüm kontrolü atlandı"
fi

echo "== 3/6  opencode.json — geçerli JSON + şablon dolu mu =="
CFG="$KOK/engine/opencode.json"
if [ ! -f "$CFG" ]; then
  hata "$CFG YOK"
elif command -v python3 >/dev/null 2>&1 && python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$CFG" 2>/dev/null; then
  ok "opencode.json geçerli JSON"
  if grep -q "KURUM_ENDPOINT" "$CFG"; then
    uyar "opencode.json içinde KURUM_ENDPOINT şablon değeri duruyor (kur.sh env'den doldurur)"
  else
    ok "şablon değeri (KURUM_ENDPOINT) doldurulmuş"
  fi
else
  hata "opencode.json GEÇERSİZ JSON"
fi

echo "== 4/6  beceriler (38 beklenir) + AGENTS.md =="
if [ -d "$KOK/knowledge/skills/approved" ]; then
  n="$(find "$KOK/knowledge/skills/approved" -mindepth 1 -maxdepth 1 -type d | wc -l)"
  if [ "$n" -eq 38 ]; then
    ok "beceri sayısı: $n"
  else
    uyar "beceri sayısı $n — 38 bekleniyordu"
  fi
else
  hata "knowledge/skills/approved dizini YOK"
fi
if [ -f "$KOK/engine/AGENTS.md" ]; then
  ok "AGENTS.md var"
else
  hata "AGENTS.md YOK"
fi

eksik=""
for d in skills/approved skills/experimental skills/generated runbooks incidents lessons-learned operations-notes architecture roadmap; do
  [ -d "$KOK/knowledge/$d" ] || eksik="$eksik $d"
done
if [ -z "$eksik" ]; then
  ok "knowledge iskeleti tam (9 dizin)"
else
  hata "knowledge/ altinda eksik dizin:$eksik"
fi

echo "== 5/6  kurum uç erişilebilirliği (bulunamazsa UYARI, hata değil) =="
KURUM_URL=""
# shellcheck disable=SC1090
if [ -f "$KOK/env" ]; then set -a; . "$KOK/env" 2>/dev/null || true; set +a; fi
case "${KURUM_URL:-}" in
  ""|*KURUM_ENDPOINT*)
    uyar "KURUM_URL doldurulmamış (env şablonu) — erişilebilirlik kontrolü atlandı"
    ;;
  *)
    if curl -sS -m 5 "${KURUM_URL%/}/models" >/dev/null 2>&1; then
      ok "uç erişilebilir: ${KURUM_URL%/}/models"
    else
      uyar "uç erişilemedi (5 sn): ${KURUM_URL%/}/models — kurum ağına bağlıyken normal olabilir, hata sayılmaz"
    fi
    ;;
esac

echo "== 6/6  izin özeti =="
if [ -f "$CFG" ] && command -v python3 >/dev/null 2>&1; then
  python3 - "$CFG" <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
p = d.get("permission", {})
print(f"  · edit={p.get('edit')} read={p.get('read')} grep={p.get('grep')} glob={p.get('glob')} list={p.get('list')}")
print(f"  · external_directory={p.get('external_directory')}")
b = p.get("bash", {})
if isinstance(b, dict):
    print(f"  · bash.*={b.get('*')}  deny-kalıp sayısı={len([k for k,v in b.items() if v=='deny'])}")
PY
  eddir="$(python3 -c "import json;print(json.load(open('$CFG')).get('permission',{}).get('external_directory'))" 2>/dev/null)"
  if [ "$eddir" = "ask" ]; then
    ok "external_directory=ask görünüyor (proje kökü dışına çıkış izin ister)"
  else
    uyar "external_directory beklenen 'ask' değil: ${eddir:-<okunamadı>}"
  fi
else
  uyar "izin özeti okunamadı (opencode.json yok/python3 yok)"
fi

echo
if [ "$HATA" -gt 0 ]; then
  kirmizi "SONUÇ: $HATA hata, $UYARI uyarı"
  exit 1
fi
yesil "SONUÇ: paket sağlam ($UYARI uyarı)"
