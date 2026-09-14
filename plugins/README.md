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
| "Şu işi şöyle yap" (usül bilgisi, karar, kontrol listesi) | **Beceri** (`skills/…/SKILL.md`) |
| Var olan komutları çalıştırmak (ssh, kubectl, ansible, curl) | **Yerleşik `bash`** |
| Deterministik iş: çıktı ayrıştırma, sayı doğrulama, format üretme | **Tool (plugin)** |
| Zorunlu kapı: yıkıcı komut engeli, kapsam dışı yol reddi | **Tool (hook) / `permission`** |

## Aday araçlar (kodlanacak — öneri, önceliği deneme belirler)

| Araç | Ne yapar | Neden beceri yetmez |
|---|---|---|
| `envanter-dogrula` | hosts.ini / CSV-XLSX ayrıştır, satır toplamlarını tek tek doğrula | Elle aritmetik hata yapıyor; deterministik olmalı |
| `rapor-uret` | Tablo → Markdown/Excel/PDF (font/kütüphane kontrolüyle) | Tekrarlı üretim, tutarlı biçim |
| `kapsam-gate` | Kök dizin dışı erişimi reddet (plugin `tool.execute.before`) | `AGENTS.md` kuralı "rica"; tool "kapı" |
| `guvenlik-kapisi` | `rm -rf`/`mkfs`/force-push desenlerini komut çalışmadan engelle | İzin kurallarına ek ikinci hat |

> Not: Bu liste **öneridir**. Gerçek öncelik, test-sunucu canlı denemesinde "canımızı yakan" noktaya göre belirlenir.
