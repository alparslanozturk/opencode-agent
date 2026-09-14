# opencode paketi — Alp (kurum içi)

Aider fork'unda biriken tecrübeyi (**38 beceri** + çalışma kuralları) opencode'a taşıyan hazır paket.
Kod geliştirme YOK — sadece ayar + içerik. Amaç: **önce denemek**, sonuç iyiyse sonra kod.

## Ne var içinde
| Dosya | Ne işe yarar |
|---|---|
| `bin/opencode` | opencode 1.18.30 — **tek ikili dosya** (185 MB), kurulum gerektirmez |
| `env` | **Doldurulacak 3 satır** (kurum endpoint + anahtar + model kimliği) |
| `opencode.json` | Sağlayıcı ayarı: kurum Qwen'i OpenAI uyumlu uçtan bağlar · 16k pencere · zaman aşımları · izin kuralları |
| `skills/` | Aider'dan aktarılan **38 beceri** (opencode'un beklediği biçimle birebir uyumlu) |
| `AGENTS.md` | Kurum kuralları: dil, envanter disiplini, güvenlik, beceri disiplini, pencere/endpoint notu |
| `kur.sh` | Tek komutla kurar (offline) — `opencode`+`oc` kısayollarını kurar, sonda `oc-dogrula.sh` çalıştırır |
| `oc-dogrula.sh` | Kurulumu doğrular (offline; kurum ucu erişilemezse hata değil uyarı verir) |
| `NASIL-CALISTIRILIR.md` | **Adım adım çalıştırma + sorun giderme** (önce bunu oku) |
| `DENEYIM-AKTARIM.md` | Aider'da öğrendiklerimizin opencode karşılığı — ne aktarıldı, ne aktarılamadı |

## Kurulum (3 adım — internet/npm gerekmez)
```bash
# 1) 3 satırı doldur:
vi env            # KURUM_URL=http://sunucu:port/v1 (+ KURUM_KEY, MODEL_ID)
# 2) kur (ikili + ayar + 38 beceri kurulur, sonda otomatik doğrulama çalışır, kısayollar: opencode + oc):
./kur.sh
# 3) çalıştır:
opencode          # kısa ad: oc
```
İlk açılışta **`/models`** → `kurum / Qwen3.6-35B-A3B-FP8` seç. Beceriler otomatik görünür.

**Elle doğrulamak istersen:** `./oc-dogrula.sh` (internet gerektirmez, kurum ucuna erişemezse hata değil uyarı verir).

## Offline güvence
`opencode.json`'daki `"npm": "@ai-sdk/openai-compatible"` alanı **çalışma anında npm/network tetiklemez** —
bu SDK opencode'un 185 MB'lık tek ikilisine **derleme zamanında gömülü**dür (binary içinde `strings` ile
doğrulanabilir; `@ai-sdk/openai-compatible` dahil 18 sağlayıcı SDK'sı statik olarak paketli). Ağ erişimi tamamen
kapalı bir `unshare --net` ortamında `opencode run` denenmiş, SDK 11 ms'de yüklenmiş, tek hata sahte uç
adresine bağlanamamak olmuş (beklenen) — npm/node_modules/lockfile hiç oluşmamış. Ayrıntı: `GELISTIRME-RAPORU-OPENCODE-CILA.md`.

## Bilmeceler (denemede bakılacaklar)
1. ~~`@ai-sdk/openai-compatible` eklentisi offline yüklenebiliyor mu?~~ **Çözüldü:** evet, ikiliye gömülü — npm gerekmiyor.
2. Kurum ucu **araç çağrısı (tool calling)** destekliyor mu? Desteklemiyorsa ajan modu çalışmaz → haber ver.
3. 16k pencerede uzun envanter okuma: kırpma/özetleme opencode'un kendi bağlam yönetimine bırakıldı (aider'daki elle bütçe yok).

## GitHub fork
`https://github.com/alparslanozturk77/opencode` (kaynak: `anomalyco/opencode`, MIT — eski adı `sst/opencode`).
Kod geliştirme gerekirse bu fork üzerinden gideriz; **şimdilik gerek yok**.

## Bu depo (git) — geliştirme burada yürür

Bu dizin artık bir **git deposu**dur (opencode ajan kiti). Bkz. `MIMARI.md` (katmanlar + yol haritası).

- **Takip edilenler:** `skills/`, `AGENTS.md`, `opencode.json`, `plugins/`, `kur.sh`, `oc-dogrula.sh`, `*.md`
- **Takip EDİLMEYENLER:** `bin/` (185 MB opencode ikilisi — ayrı `opencode-paket.tar.gz` ile taşınır), `env` (sırlar)
- Genişletme sırası: `opencode.json` → `AGENTS.md` → `skills/` → `plugins/` → (yetmezse) fork
