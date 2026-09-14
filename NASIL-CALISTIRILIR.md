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
