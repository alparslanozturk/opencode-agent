#!/usr/bin/env bash
# =============================================================================
#  kur.sh — opencode paketi kurucusu (kurum içi, offline; ağ/npm gerekmez).
#
#  Kullanım:  cd /root/opencode-agent && ./kur.sh
#    --baglanti-yok     kısayolları kurma (yalnız ikili + ayar + beceri)
#    --baglanti-zorla   mevcut başka bir 'opencode'/'oc' varsa yedekle ve üzerine yaz
#    --tum-beceriler    38 becerinin tümünü kur (varsayılan: 6-10 çekirdek beceri, bkz. CORE_SKILLS)
#  Ortam değişkeni: KISAYOL_DIZIN (varsayılan /usr/local/bin, yazılamıyorsa ~/.local/bin)
# =============================================================================
set -euo pipefail
KOK="$(cd "$(dirname "$0")" && pwd)"

# Çekirdek beceri listesi (Aşama 2, danışma-2 kararı: 38 → 6-10). Kalan 29 beceri
# knowledge/skills/approved/ altında kalır, --tum-beceriler ile hepsi kurulabilir.
CORE_SKILLS=(ansible k8s-rancher rhel-yonetim filo-durum-kontrolu rapor-uret hata-ayikla performans sistem-guncelleme depolama)
if [ ! -f "$KOK/env" ]; then
  echo "!! $KOK/env bulunamadi." >&2
  echo "   Olustur ve 3 satiri doldur:" >&2
  if [ -f "$KOK/env.example" ]; then
    echo "     cp $KOK/env.example $KOK/env && vi $KOK/env" >&2
  else
    echo "     Su 3 satirla olustur (degerleri kurumdan al):" >&2
    echo "       KURUM_URL=http://<endpoint>:<port>/v1" >&2
    echo "       KURUM_KEY=dummy" >&2
    echo "       MODEL_ID=/data/models--Qwen--Qwen36-35B-A3B-FP8" >&2
  fi
  echo "   (env bilerek git'te degil: URL + anahtar repoda durmasin.)" >&2
  exit 1
fi
# shellcheck disable=SC1090
. "$KOK/env"

if [ ! -x "$KOK/bin/opencode" ] && [ -f "$KOK/bin/opencode.tar.xz" ]; then
  echo ">> bin/opencode yok — bin/opencode.tar.xz aciliyor (bir kez)..."
  tar xJf "$KOK/bin/opencode.tar.xz" -C "$KOK/bin" && chmod +x "$KOK/bin/opencode"
fi

if [ ! -f "$KOK/bin/opencode" ]; then
  echo "!! $KOK/bin/opencode yok." >&2
  echo "   Cozum: git ile gelen bin/opencode.tar.xz'yi ac  ->  tar xJf $KOK/bin/opencode.tar.xz -C $KOK/bin" >&2
  echo "      ya da kurumda kurulu opencode ikilisini $KOK/bin/opencode olarak koy." >&2
  exit 1
fi

BAGLANTI_YOK=0
BAGLANTI_ZORLA=0
TUM_BECERILER=0
for arg in "$@"; do
  case "$arg" in
    --baglanti-yok)   BAGLANTI_YOK=1 ;;
    --baglanti-zorla) BAGLANTI_ZORLA=1 ;;
    --tum-beceriler)  TUM_BECERILER=1 ;;
    -h|--help) echo "Kullanım: $0 [--baglanti-yok] [--baglanti-zorla] [--tum-beceriler]"; exit 0 ;;
    *) echo "Bilinmeyen argüman: $arg" >&2; exit 2 ;;
  esac
done

yesil()   { printf '\033[32m%s\033[0m\n' "$*"; }
kirmizi() { printf '\033[31m%s\033[0m\n' "$*"; }
sari()    { printf '\033[33m%s\033[0m\n' "$*"; }

case "$KURUM_URL" in
  *KURUM_ENDPOINT*) echo "!! Önce $KOK/env içindeki KURUM_URL'i doldur."; exit 1;;
esac

echo "== 1/4  ikili =="
mkdir -p "$HOME/.opencode/bin"
install -m 0755 "$KOK/bin/opencode" "$HOME/.opencode/bin/opencode"
yesil "  kuruldu: $HOME/.opencode/bin/opencode"

echo "== 2/4  ayar + kurallar + beceriler =="
mkdir -p "$HOME/.config/opencode"
[ -f "$KOK/engine/AGENTS.md" ] && cp -f "$KOK/engine/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
rm -rf "$HOME/.config/opencode/skills"; mkdir -p "$HOME/.config/opencode/skills"
if [ "$TUM_BECERILER" = 1 ]; then
  cp -r "$KOK/knowledge/skills/approved/." "$HOME/.config/opencode/skills/"
  sari "  --tum-beceriler: 38 becerinin tümü kuruldu (taban bağlam büyür)"
else
  for ad in "${CORE_SKILLS[@]}"; do
    if [ -d "$KOK/knowledge/skills/approved/$ad" ]; then
      cp -r "$KOK/knowledge/skills/approved/$ad" "$HOME/.config/opencode/skills/$ad"
    else
      sari "  ! çekirdek beceri bulunamadı: $ad"
    fi
  done
fi
yesil "  beceri: $(ls "$HOME/.config/opencode/skills" | wc -l) adet kuruldu (toplam mevcut: $(ls "$KOK/knowledge/skills/approved" | wc -l), tümü için: --tum-beceriler)"

# ---------------------------------------------------------------------------
#  Bağlam penceresi tespiti — uydurma değer yok, kurum uçtan ölç (best-effort)
# ---------------------------------------------------------------------------
TESPIT_EDILEN_PENCERE=""
TESPIT_KAYNAK=""
case "$KURUM_URL" in
  ""|*KURUM_ENDPOINT*) ;;
  *)
    MODELS_JSON="$(curl -sS --max-time 10 -H "Authorization: Bearer $KURUM_KEY" "${KURUM_URL%/}/models" 2>/dev/null || true)"
    if [ -n "$MODELS_JSON" ]; then
      TESPIT_EDILEN_PENCERE="$(python3 - "$MODELS_JSON" <<'PY' 2>/dev/null || true
import json, sys
raw = sys.argv[1]
KEYS = ("max_model_len", "context_length", "max_context_length", "context_window")
try:
    d = json.loads(raw)
except Exception:
    sys.exit(0)
candidates = []
if isinstance(d, dict):
    candidates.append(d)
    if isinstance(d.get("data"), list):
        candidates.extend(x for x in d["data"] if isinstance(x, dict))
for c in candidates:
    for k in KEYS:
        v = c.get(k)
        if isinstance(v, (int, float)) and v > 0:
            print(int(v))
            sys.exit(0)
PY
)"
      [ -n "$TESPIT_EDILEN_PENCERE" ] && TESPIT_KAYNAK="${KURUM_URL%/}/models"
    fi
    ;;
esac

if [ -n "$TESPIT_EDILEN_PENCERE" ]; then
  yesil "  bağlam penceresi: $TESPIT_EDILEN_PENCERE token (kaynak: $TESPIT_KAYNAK)"
elif [ -n "${KURUM_MAX_CONTEXT:-}" ]; then
  TESPIT_EDILEN_PENCERE="$KURUM_MAX_CONTEXT"
  yesil "  bağlam penceresi: $TESPIT_EDILEN_PENCERE token (kaynak: env KURUM_MAX_CONTEXT)"
else
  sari "  ! bağlam penceresi tespit edilemedi (uç yanıt vermedi/alan yok) — mevcut opencode.json değeri korunuyor"
  sari "    İstersen $KOK/env içine KURUM_MAX_CONTEXT=<token> ekleyip yeniden çalıştır."
fi

python3 - "$KOK/engine/opencode.json" "$HOME/.config/opencode/opencode.json" "$KURUM_URL" "$KURUM_KEY" "$MODEL_ID" "$TESPIT_EDILEN_PENCERE" <<'PY'
import json, sys
src, dst, url, key, mid, ctx = sys.argv[1:7]
d = json.load(open(src, encoding="utf-8"))
p = d["provider"]["kurum"]
p["options"]["baseURL"] = url
p["options"]["apiKey"] = key
m = list(p["models"])[0]
p["models"][m]["id"] = mid

if ctx:
    ctx_n = int(ctx)
    p["models"][m]["limit"]["context"] = ctx_n
    # thrash'i bitirmek icin makul degerler (asama 2, GOREV-ASAMA-2.md paket A):
    # reserved = tampon (taşmayı önler), preserve_recent_tokens = compaction sonrası korunan bütçe.
    d.setdefault("compaction", {})
    d["compaction"]["auto"] = True
    d["compaction"]["prune"] = True
    d["compaction"]["reserved"] = max(1024, min(4096, ctx_n // 8))
    d["compaction"]["preserve_recent_tokens"] = max(2048, min(8192, ctx_n // 4))
    d["compaction"]["tail_turns"] = 2

json.dump(d, open(dst, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY
yesil "  config: $HOME/.config/opencode/opencode.json"

mkdir -p "$HOME/.config/opencode/plugins"
if compgen -G "$KOK/engine/plugins/*.ts" > /dev/null || compgen -G "$KOK/engine/plugins/*.js" > /dev/null; then
  cp -f "$KOK"/engine/plugins/*.ts "$HOME/.config/opencode/plugins/" 2>/dev/null || true
  cp -f "$KOK"/engine/plugins/*.js "$HOME/.config/opencode/plugins/" 2>/dev/null || true
  yesil "  plugin: $(ls "$HOME/.config/opencode/plugins" | wc -l) adet → ~/.config/opencode/plugins (açılışta okunur, tekrar açman gerekebilir)"
else
  sari "  engine/plugins/ altında .ts/.js yok — plugin kurulumu atlandı"
fi

# ---------------------------------------------------------------------------
#  3) ripgrep — opencode'un grep/glob araçları bunu ~/.cache/opencode/bin/rg'de
#     bekliyor; yoksa ilk kullanımda ağdan indirmeye çalışıyor (kurum ağı
#     kapalıysa "ripgrep execution failed" ile kırılıyor, bkz. EK-4). Bu pakette
#     opencode'un kendi indirdiği statik ikili bin/ripgrep.tar.xz olarak taşınıyor.
# ---------------------------------------------------------------------------
echo "== 3/4  ripgrep =="
RG_CACHE_DIZIN="${XDG_CACHE_HOME:-$HOME/.cache}/opencode/bin"
if command -v rg >/dev/null 2>&1; then
  yesil "  rg zaten PATH'te: $(command -v rg) ($(rg --version | head -1))"
elif [ -x "$RG_CACHE_DIZIN/rg" ]; then
  yesil "  rg zaten kurulu: $RG_CACHE_DIZIN/rg"
elif [ -f "$KOK/bin/ripgrep.tar.xz" ]; then
  mkdir -p "$RG_CACHE_DIZIN"
  tar xJf "$KOK/bin/ripgrep.tar.xz" -C "$RG_CACHE_DIZIN"
  chmod +x "$RG_CACHE_DIZIN/rg"
  if "$RG_CACHE_DIZIN/rg" --version >/dev/null 2>&1; then
    yesil "  rg kuruldu: $RG_CACHE_DIZIN/rg ($("$RG_CACHE_DIZIN/rg" --version | head -1))"
  else
    kirmizi "  ! rg kopyalandı ama çalışmadı (mimari uyuşmazlığı olabilir) — elle kontrol et: $RG_CACHE_DIZIN/rg --version"
  fi
else
  sari "  ! bin/ripgrep.tar.xz yok ve rg PATH'te değil — dosya arama (grep/glob) kırık kalabilir"
  sari "    Elle kur: statik bir 'rg' ikilisini $RG_CACHE_DIZIN/rg olarak koy (chmod +x)."
fi

# ---------------------------------------------------------------------------
#  4) 'opencode' + 'oc' kısayolları
# ---------------------------------------------------------------------------
echo "== 4/4  'opencode' + 'oc' kısayolları =="
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
echo "  Kurulum kökü:     $KOK"
echo "  Kurallar/ayar:    $HOME/.config/opencode/  (AGENTS.md, opencode.json, skills/, plugins/)"
echo
echo "  Başlat:  opencode   (kısa ad: oc)"
echo "  İlk açılışta /models → kurum / Qwen3.6-35B-A3B-FP8 seç."
echo
sari "  NOT: opencode'u VERİNİN OLDUĞU dizinde aç (ör. envanter işi için: cd ~/ansible && opencode)."
sari "       Proje kökü dışına çıkmak 'external_directory' izin kapısı çıkarır; boş bir dizinden"
sari "       açıp üst dizinleri aratmak yerine doğrudan ilgili dizinde başlat."
