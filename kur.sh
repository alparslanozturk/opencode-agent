#!/usr/bin/env bash
# =============================================================================
#  kur.sh — opencode paketi kurucusu (kurum içi, offline; ağ/npm gerekmez).
#
#  Kullanım:  cd /root/opencode-alp && ./kur.sh
#    --baglanti-yok     kısayolları kurma (yalnız ikili + ayar + beceri)
#    --baglanti-zorla   mevcut başka bir 'opencode'/'oc' varsa yedekle ve üzerine yaz
#  Ortam değişkeni: KISAYOL_DIZIN (varsayılan /usr/local/bin, yazılamıyorsa ~/.local/bin)
# =============================================================================
set -euo pipefail
KOK="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$KOK/env" ]; then
  echo "!! $KOK/env bulunamadi." >&2
  echo "   Sablondan olustur ve 3 satiri doldur:" >&2
  echo "     cp $KOK/env.example $KOK/env && vi $KOK/env" >&2
  echo "   (env bilerek git'te degil: URL + anahtar repoda durmasin.)" >&2
  exit 1
fi
# shellcheck disable=SC1090
. "$KOK/env"

if [ ! -f "$KOK/bin/opencode" ]; then
  echo "!! $KOK/bin/opencode yok — ikili git'te degil (bilerek)." >&2
  echo "   Cozum: paketten kopyala      tar xJf opencode-paket.tar.xz -C /root" >&2
  echo "      ya da kurumda kurulu opencode ikilisini $KOK/bin/opencode olarak koy." >&2
  exit 1
fi

BAGLANTI_YOK=0
BAGLANTI_ZORLA=0
for arg in "$@"; do
  case "$arg" in
    --baglanti-yok)   BAGLANTI_YOK=1 ;;
    --baglanti-zorla) BAGLANTI_ZORLA=1 ;;
    -h|--help) echo "Kullanım: $0 [--baglanti-yok] [--baglanti-zorla]"; exit 0 ;;
    *) echo "Bilinmeyen argüman: $arg" >&2; exit 2 ;;
  esac
done

yesil()   { printf '\033[32m%s\033[0m\n' "$*"; }
kirmizi() { printf '\033[31m%s\033[0m\n' "$*"; }
sari()    { printf '\033[33m%s\033[0m\n' "$*"; }

case "$KURUM_URL" in
  *KURUM_ENDPOINT*) echo "!! Önce $KOK/env içindeki KURUM_URL'i doldur."; exit 1;;
esac

echo "== 1/3  ikili =="
mkdir -p "$HOME/.opencode/bin"
install -m 0755 "$KOK/bin/opencode" "$HOME/.opencode/bin/opencode"
yesil "  kuruldu: $HOME/.opencode/bin/opencode"

echo "== 2/3  ayar + kurallar + beceriler =="
mkdir -p "$HOME/.config/opencode"
[ -f "$KOK/engine/AGENTS.md" ] && cp -f "$KOK/engine/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
rm -rf "$HOME/.config/opencode/skills"; mkdir -p "$HOME/.config/opencode/skills"
cp -r "$KOK/knowledge/skills/approved/." "$HOME/.config/opencode/skills/"

python3 - "$KOK/engine/opencode.json" "$HOME/.config/opencode/opencode.json" "$KURUM_URL" "$KURUM_KEY" "$MODEL_ID" <<'PY'
import json, sys
src, dst, url, key, mid = sys.argv[1:6]
d = json.load(open(src, encoding="utf-8"))
p = d["provider"]["kurum"]
p["options"]["baseURL"] = url
p["options"]["apiKey"] = key
m = list(p["models"])[0]
p["models"][m]["id"] = mid
json.dump(d, open(dst, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY
yesil "  config: $HOME/.config/opencode/opencode.json"
yesil "  beceri: $(ls "$HOME/.config/opencode/skills" | wc -l) adet → ~/.config/opencode/skills"

# ---------------------------------------------------------------------------
#  3) 'opencode' + 'oc' kısayolları
# ---------------------------------------------------------------------------
echo "== 3/3  'opencode' + 'oc' kısayolları =="
if [ "$BAGLANTI_YOK" = 1 ]; then
  sari "  atlandı (--baglanti-yok)"
else
  HEDEF_DIZIN="${KISAYOL_DIZIN:-/usr/local/bin}"
  if [ ! -d "$HEDEF_DIZIN" ] || { [ ! -w "$HEDEF_DIZIN" ] && [ "$(id -u)" != 0 ]; }; then
    HEDEF_DIZIN="$HOME/.local/bin"; mkdir -p "$HEDEF_DIZIN"
    sari "  ${KISAYOL_DIZIN:-/usr/local/bin} yazılamıyor → $HEDEF_DIZIN kullanılıyor"
  fi
  BENIM="$HOME/.opencode/bin/opencode"

  kisayol_kur() { # <ad>
    local ad="$1" baglanti="$HEDEF_DIZIN/$1" mevcut
    mevcut="$(readlink -f "$baglanti" 2>/dev/null || true)"
    if [ ! -e "$baglanti" ] && [ ! -L "$baglanti" ]; then
      ln -sfn "$BENIM" "$baglanti"
      yesil "  kısayol kuruldu: $baglanti → $BENIM"
    elif [ "$mevcut" = "$BENIM" ]; then
      yesil "  kısayol zaten doğru: $baglanti"
    elif [ "$BAGLANTI_ZORLA" = 1 ]; then
      yedek="$baglanti.bak-$(date +%Y%m%d-%H%M%S)"
      mv "$baglanti" "$yedek"
      sari "  mevcut '$ad' yedeklendi: $yedek"
      ln -sfn "$BENIM" "$baglanti"
      yesil "  kısayol kuruldu: $baglanti → $BENIM"
    else
      sari "  $baglanti zaten var ve başka bir kurulumu gösteriyor: ${mevcut:-<çözülemedi>}"
      echo  "    Üzerine yazmak isterseniz: $0 --baglanti-zorla   (yedek alınır)"
    fi
  }
  kisayol_kur opencode
  kisayol_kur oc

  case ":$PATH:" in
    *":$HEDEF_DIZIN:"*) ;;
    *) sari "  NOT: $HEDEF_DIZIN PATH'te değil (export PATH=\"$HEDEF_DIZIN:\$PATH\")" ;;
  esac
fi

echo
echo "== doğrulama =="
"$KOK/oc-dogrula.sh" || true

echo
yesil "BİTTİ."
echo "  Başlat:  opencode   (kısa ad: oc)"
echo "  İlk açılışta /models → kurum / Qwen3.6-35B-A3B-FP8 seç."
