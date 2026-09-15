# NASIL ÇALIŞTIRILIR — opencode (kurum içi / offline)

> Hedef: `test-sunucu` (RHEL). Kaynak kod **gerekmez** — tek ikili + ayar + beceriler yeter.
> Sonuçta çalışacak komut: **`opencode`** (kısa ad: **`oc`**).
> **Offline güvence:** `opencode.json`'daki `"npm": "@ai-sdk/openai-compatible"` alanı çalışma anında
> npm/network tetiklemez — bu SDK opencode'un tek ikilisine derleme zamanında gömülüdür. İnternet/npm
> erişimi olmayan bir makinede de sorunsuz çalışır (kanıt: `GELISTIRME-RAPORU-OPENCODE-CILA.md`).

---

## 3 adımda kurulum

```bash
# 1) paketi getir ve 3 satırı doldur
tar xJf opencode-paket.tar.xz -C /root      # -> /root/opencode-agent/   (.tar.gz ise: tar xzf ...)
vi /root/opencode-agent/env                    # KURUM_URL=http://sunucu:port/v1 (+ KURUM_KEY, MODEL_ID)

# 2) kur (offline; ikili + ayar + 38 beceri + oc/opencode kısayolları kurulur, sonda otomatik doğrulama çalışır)
/root/opencode-agent/kur.sh

# 3) çalıştır
cd /root/work/aider   # hangi dizinde çalışacaksan orada aç
opencode              # kısa ad: oc
```
**git ile çektiysen** (paket yerine `git pull` ile kuruyorsan):
```bash
cd /root/ai/opencode-agent   # repo nerede ise
cp env.example env 2>/dev/null || vi env   # env oluştur + 3 satırı doldur
./kur.sh
```
> ℹ️ `bin/opencode` sıkıştırılmış hâlde repoda: **`bin/opencode.tar.xz`** (43 MB) → `kur.sh` ilk çalıştırmada kendisi açar, elle bir şey yapmak gerekmez.

İlk açılışta **`/models`** → `kurum / Qwen3.6-35B-A3B-FP8` seç (bir kez; sonra hatırlar).

**Doğrulama** (istediğin zaman tekrar çalıştırılabilir, internet gerektirmez):
```bash
/root/opencode-agent/oc-dogrula.sh
```

---

## Depo düzeni: motor / bilgi

| Katman | Yer | Ne |
|---|---|---|
| **Motor** | `engine/` | `AGENTS.md` (kurallar) · `opencode.json` (ayar) · `plugins/` (araç) |
| **Bilgi** | `knowledge/` | `skills/approved/` (canlı beceriler) · `experimental/` · `generated/` · `runbooks/` · `incidents/` · `lessons-learned/` · `operations-notes/` · `architecture/` · `roadmap/` |

`kur.sh` becerileri **yalnız `knowledge/skills/approved/`**'dan kurar; ajan `experimental/` + `generated/`'ı okumaz
(onay kapısı — *"AI kendi kendine öğrenmez, öğrenme önerir"*).

---

## Sorun giderme

| Belirti | Ne yapılır |
|---|---|
| `Endpoint 180 sn'dir yeni içerik göndermedi` | Zaman aşımları 900/300/180 sn'ye çekildi; sorun model tarafında — aynı isteği üst üste yineleme |
| Uzun dosya/log okurken kesilme | Pencere **16k**; model `offset`/`limit` ile parça parça okumalı |
| Beceriler görünmüyor | `~/.config/opencode/skills/` altında mı? `opencode debug skill` ile say |
| Ayar değişti, etki yok | opencode ayarı açılışta bir kez okunur, sıcak yükleme yok → opencode'u tamamen kapat-aç |
| TUI bozuk görünüyor (glif/kutu) | Terminal fontu/UTF-8; `TERM=xterm-256color` |
| `opencode`/`oc` PATH'te yok | `kur.sh` çıktısındaki NOT satırına bak; `export PATH="<kısayol-dizini>:$PATH"` |
| Var olan başka bir `opencode`/`oc` kısayolu var | `kur.sh` uyarır ve dokunmaz; üzerine yazmak için `kur.sh --baglanti-zorla` (eskisini yedekler) |
| Ekranda sürekli `⠋ Thinking` + `Compaction`/`Build` art arda dönüyor, hiç ilerlemiyor | **Bilinen sorun, aşağıya bak** ("Compaction thrash / sonsuz döngü") |
| Çalışma dizini boş (`ll` → `total 0`) ama opencode yine de çalışıyor | Paket o makinede **açılmamış olabilir** — aşağıdaki "Dağıtım kontrolü"ne bak |

---

## Compaction thrash / sonsuz döngü (2026-09-15, kanıtlı kök neden)

**Belirti:** Basit bir istekte (`ls`, "dizini listele") bile ekran sürekli `⠋ Thinking` →
`Compaction · Qwen...` → `Build · ...` arasında dönüyor, context doluyor (`%86 used` gibi), agent
tool çağırmak yerine "Next Move / Receive user response..." tipi plan metni üretip duruyor. `esc` ile
kesmek gerekiyor.

**Kök neden (iki katmanlı, offline olarak `bin/opencode` ile ölçüldü — kurum endpoint'i gerekmedi):**

1. **Baseline bağlam zaten pencerenin ~%87'si.** Boş bir dizinde, 38 becerili bu paketle, modele
   giden **ilk** istek (hiç konuşma geçmişi yokken) şu boyutta:
   - opencode'un yerleşik sistem promptu: ~8.9K karakter (bizim değiştiremeyeceğimiz, ikiliye gömülü)
   - bizim `AGENTS.md`: ~2.5K karakter
   - 38 becerinin `<name>+<description>+<location>` listesi (tam içerik değil — mekanizma zaten
     "talep üzerine" çalışıyor): ~16.9K karakter
   - araç (tool) şemaları (`bash/edit/read/grep/glob/write/skill/task/todowrite/webfetch`): ~21.1K karakter
   - **Toplam ≈ 48.7K karakter ≈ ~14.3K token** — 16384'lük pencerenin **%87'si**, sahadaki
     "14,087 tokens — %86 used" görüntüsüyle birebir örtüşüyor.
   - Ölçüm yöntemi: `engine/opencode.json`'daki `baseURL`'i yerel bir mock HTTP sunucuya yönlendirip
     (`opencode run "..." --format json`), sunucuya gelen gerçek istek gövdesi kaydedildi — hiçbir
     tahmin/varsayım yok, gerçek bayt sayısı.
2. **Model araç çağırmayan (plan metni gibi) bir yanıt döndürdüğünde, opencode 1.18.30'un adım
   döngüsü DURMUYOR.** Aynı senaryo yerel mock ile yeniden üretildi: mock, `finish_reason: "stop"`
   ve düz metin içeren geçerli bir OpenAI-uyumlu yanıt döndürdüğünde, opencode **aynı isteği
   saniyede onlarca kez, hiç bekleme/üst sınır olmadan** tekrar gönderdi (12 saniyede 178 adım,
   her `step-finish` olayı `"reason":"unknown"`). `doom_loop` iznini `"deny"` yapmak bu döngüyü
   **durdurmadı** — bu desen mevcut doom-loop korumasının kapsamı dışında.
   → Bu, **modelden bağımsız, ikiliye gömülü bir harness hatası**; repo içinden (AGENTS.md,
   opencode.json, skill) düzeltilemez. Sahadaki "Compaction" döngüsü muhtemelen bunun büyümüş hâli:
   gerçek model her turda farklı metin ürettiği için konuşma geçmişi büyüyor → auto-compact tetikleniyor
   → döngü modeli yine araç çağırmıyor → tekrar büyüyor → tekrar compact... sonsuz.

**Bu depoda yapılan azaltmalar (kökü düzeltmez, ama alanı büyütür + tetiklenme ihtimalini azaltır):**
- `engine/opencode.json`: `permission.webfetch/task/todowrite = "deny"`. Ölçülen etki: araç şeması
  21.1K → 13.1K karakter (**~8K karakter / bağlamın ~%16'sı geri kazanıldı**). Ayrıca `task` (alt-agent
  başlatma) bu 16k'lık modelde özellikle tehlikeli: her alt-agent kendi ~14K'lık baseline'ını yeniden
  yükler — iç içe thrash riski. `webfetch` zaten AGENTS.md'deki "dış ağa veri gönderme" kuralıyla çelişiyordu.
- `engine/AGENTS.md`: "Tek adım disiplini" ve "Çalışma dizini boşsa" kuralları eklendi (bkz. dosya) —
  modelin araç çağırmayıp plan metni üretme ihtimalini azaltmayı hedefler; harness hatasını düzeltmez.

**Canlıda denenebilecek (bu ortamda test edilemedi, gerçek kurum Qwen erişimi gerekir):**
- `OPENCODE_DISABLE_AUTOCOMPACT=1 opencode` — auto-compact'i kapatıp döngü davranışını "compaction"
  gürültüsü olmadan gözlemlemek için bir teşhis anahtarı (kalıcı çözüm değil; context taşarsa sert hata
  verir).
- `opencode.json` → `"compaction": {"auto": false}` aynı anahtarın config karşılığı (yerleşik
  `customize-opencode` skill'inde belgeli alan).
- Döngü başladığında `esc` ile kesip tekrar aynı isteği vermek yerine, daha dar/somut bir istek
  ("sadece `ls -la` çalıştır, yorum yapma") vermek — plan-metni tetiklenme ihtimalini pratikte azaltıyor.
- Gerçek kurum Qwen'in **tek turda geçerli `tool_calls` üretip üretmediği** hâlâ doğrulanmadı (bu ortamda
  yalnız harness'in tool-call'u doğru şekilde YÜRÜTTÜĞÜ doğrulanabildi, modelin ÜRETTİĞİ doğrulanamadı) —
  aşağıdaki "Dağıtım kontrolü"nden sonra 3 gerçek görevle bakılmalı.

### Gerçek context penceresini ölçme (yapılmadı — repo içinden garanti edilemez)
`limit.context: 16384` şu an **doğrulanmamış bir varsayım** (aider'dan aktarılmış). Büyütmeden önce:
1. Kurum vLLM endpoint'inin `/v1/models` ya da sunucu başlatma loglarından `max_model_len` değerini iste.
2. Ya da `opencode.json`'da `limit.context`'i küçük adımlarla artırıp, endpoint'in "context length exceeded"
   benzeri bir hata döndürdüğü noktayı bul.
Doğrulanmadan büyütülürse: model sınırı aşan bir istek gönderilir, endpoint muhtemelen sert hata döner
(sessiz kesilmeden daha iyi, ama yine de yanlış bir sayı üstünde plan yapılmış olur).

### Dağıtım kontrolü (Vaka 2: srvsatellite'ta boş çalışma dizini)
`/root/ai/work/opencode-agent` gibi bir dizinin **boş olması normaldir** — `kur.sh`, `AGENTS.md`'yi ve
becerileri **global** `~/.config/opencode/`'a kurar, proje dizinine değil (yukarıdaki "3 adımda kurulum"a
bak: adım 3'te `cd` edilen dizin keyfi bir çalışma dizinidir, paketin kendisi değil). Yani **boş dizin
başlı başına "kurallar yüklenmedi" anlamına gelmez** — test ederken bunu doğrula:
```bash
ls ~/.config/opencode/AGENTS.md          # varsa: global kurallar kurulu
opencode debug skill 2>&1 | grep -c '"name"'   # 38 civarı beceri + yerleşikler görünmeli
```
Eğer bu ikisi de boşsa/yoksa, o makinede **`kur.sh` hiç çalıştırılmamış** demektir — paket açılmış olsa
bile kurulum adımı atlanmış olabilir; `kur.sh`'ı çalıştır.

---

## Dizin kapsamı davranışı (Alp kuralı, 2026-09-11)

- Proje **içinde** okuma/arama serbest; **proje kökünün dışına çıkmak = izin ister** (`external_directory: "ask"`).
- `AGENTS.md`: açılışta çalışma dizinini duyur, `cd` ile başka klasöre geçme, kök dışında `find`/`grep`/`ls` yapma.
- **Sertleştirmek istersen:** `opencode.json` → `"external_directory": "deny"` (hiç sormaz, direkt engeller).
- Kabuk komutları yine sorar (`bash: { "*": "ask" }`); `rm -rf`, `mkfs`, force-push **deny**.

---

## Yanındaki kol: aider (fork)

```bash
cd /root/work/aider
./kur.sh          # venv + paketleri kurar (birkaç dakika), tekrar çalıştırılabilir
aider             # ya da venv/bin/aider
```
- **İlk açılışta:** `/model-ekle` → kurum endpoint adresi + model + anahtar; sonrasında her dizinde düz `aider` yeter.
- **Modlar:** `shift+tab` → `⏸ plan` → `⏵ onay` → `⏵⏵ oto` (plan modu hiçbir dosyaya dokunmaz).
- Glif/kutu bozulursa: program içinde `/terminal-setup` ya da `AIDER_ASCII=1 aider`.
- Ayrıntılı kurulum: `/root/work/aider/README.md` ("Kurulum" bölümü).

---

## Dosya düzeni

| Ne | Nerede |
|---|---|
| opencode ikilisi | `~/.opencode/bin/opencode` · kısayollar: `opencode` / `oc` (`/usr/local/bin` ya da `~/.local/bin`) |
| opencode ayarı | `~/.config/opencode/opencode.json` |
| kurallar | `~/.config/opencode/AGENTS.md` |
| beceriler | `~/.config/opencode/skills/<ad>/SKILL.md` (38 adet) |
| paket (kaynak dosyalar) | `/root/opencode-agent/` |
| kaynak klonu (çalıştırmak için gerekmez) | `/root/work/opencode` |
| aider fork + venv | `/root/work/aider/` |

---
*Patron/Doktor · 2026-09-14 · opencode v1.18.30*
