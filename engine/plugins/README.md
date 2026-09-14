# plugins/ — araç (tool) katmanı

opencode'a **yeni araç** eklemenin doğru yolu: **yerel TS/JS plugin** (offline'ı bozmaz).

- Konum: `.opencode/plugins/` (proje) veya `~/.config/opencode/plugins/` (global)
- Custom tool: `import { type Plugin, tool } from "@opencode-ai/plugin"` + Zod şeması (`args`)
- Hook'lar: `tool.execute.before` / `tool.execute.after`, `session.idle`, `session.compacted`,
  `permission.asked`, `shell.env`, `file.edited`, `todo.updated` …
- Ağırlıklı yükleme yok: opencode ayarı **açılışta bir kez** okur → plugin ekleyince kapat-aç.

⚠️ **npm plugin KULLANMA** — açılışta Bun ile npm'den çeker, kurum offline'ını bozar.
Yerel dosya plugin tercih edilir (gerekirse yanına `package.json` ile bağımlılık bildirilir).

## Nerede `beceri` yeter, nerede `tool` gerekir?

| İhtiyaç | Katman |
|---|---|
| "Şu işi şöyle yap" (usül bilgisi, karar, kontrol listesi) | **Beceri** (`knowledge/skills/approved/…/SKILL.md`) |
| Var olan komutları çalıştırmak (ssh, kubectl, ansible, curl) | **Yerleşik `bash`** |
| Deterministik iş: çıktı ayrıştırma, sayı doğrulama, format üretme | **Tool (plugin)** |
| Zorunlu kapı: yıkıcı komut engeli, kapsam dışı yol reddi | **Tool (hook) / `permission`** |

## Mevcut plugin'ler

| Dosya | Ne yapar | Durum |
|---|---|---|
| `audit-log.ts` | `tool.execute.before`/`after` + `session.idle` hook'larıyla her araç çağrısını `AUDIT-FORMAT.md` §2 şemasına uyan, hash zincirli (§3) bir JSONL satırı olarak `/var/log/ops-agent/audit.jsonl`'a yazar. Bağımlılıksız (yalnız Node/Bun çekirdek modülleri: `fs`, `crypto`, `child_process`, `os`, `path`). **Faz 0'ın ilk gerçek plugin'i.** | Kodlandı, birim testleriyle doğrulandı (bkz. `notlar/FAZ0-RAPOR.md`) |

`audit-log.ts`, `kur.sh` tarafından `~/.config/opencode/plugins/`'e kopyalanır (bkz. bu dosyanın kur.sh'daki
"plugin" adımı) — auto-discovery mekanizmasıyla ek config'e gerek kalmadan yüklenir.

### `audit-log.ts` bilinen sınırlar (Faz 0 sonrası ele alınacak)

- `task_id`, `gen_ai.usage.input_tokens/output_tokens`, `gen_ai.request.model_digest`: opencode 1.18.30'da
  `tool.execute.*` hook girdisinde bu bilgi yok; alanlar `null` yazılır (fabrikasyon yok).
- `policy_decision`: hook seviyesinde `allow`/`deny` ayrımı güvenilir gözlemlenemiyor (izin reddi genelde
  `tool.execute.after` hiç tetiklenmeden istisna fırlatıyor); v1 sezgisel kural kullanır — bkz. rapor.
- Çok-oturumlu eşzamanlı yazımda tam dosya kilidi yok (v1 tek-yazar varsayımı, `THREAT-MODEL.md` "tek makine"
  kapsamıyla uyumlu).

## Aday araçlar (henüz kodlanmadı — öneri, önceliği deneme belirler)

| Araç | Ne yapar | Neden beceri yetmez |
|---|---|---|
| `envanter-dogrula` | hosts.ini / CSV-XLSX ayrıştır, satır toplamlarını tek tek doğrula | Elle aritmetik hata yapıyor; deterministik olmalı |
| `rapor-uret` | Tablo → Markdown/Excel/PDF (font/kütüphane kontrolüyle) | Tekrarlı üretim, tutarlı biçim |
| `kapsam-gate` | Kök dizin dışı erişimi reddet (plugin `tool.execute.before`) | `AGENTS.md` kuralı "rica"; tool "kapı" |
| `guvenlik-kapisi` | `rm -rf`/`mkfs`/force-push desenlerini komut çalışmadan engelle | İzin kurallarına ek ikinci hat |

> Not: Bu liste **öneridir**. Gerçek öncelik, test-sunucu canlı denemesinde "canımızı yakan" noktaya göre belirlenir.
