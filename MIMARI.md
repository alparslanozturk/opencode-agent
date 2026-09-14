# MİMARİ — opencode ajan kiti

Aider fork'unda (15 faz) biriken tecrübeyi **opencode**'a taşıyan ajan kiti.
Bundan sonraki kodlama ajanı geliştirmesi bu depo üzerinden yürür. Referans sürüm: **opencode 1.18.30**.

## Katmanlar

| # | Katman | Nedir | Nerede |
|---|---|---|---|
| 1 | **Beceri (skill)** | Tekrar kullanılabilir usül bilgisi | `skills/<ad>/SKILL.md` (frontmatter: `name`+`description`) |
| 2 | **Araç (tool)** | Modelin çağırdığı fonksiyon | Yerleşik + `plugins/` (yerel TS) + MCP |
| 3 | **Ajan** | Ayrı prompt/model/izinli asistan | `opencode.json` → `agent` veya `.opencode/agents/*.md` |
| 4 | **Kural (rule)** | Davranış direktifi | `AGENTS.md` (proje kökü ve/veya global) |
| 5 | **Hafıza** | Kalıcılık | opencode'ta **otomatik yok** → AGENTS.md + beceriler + notlar |

### 1) Beceriler
- opencode becerileri şu konumlardan okur: `.opencode/skills/`, `~/.config/opencode/skills/`,
  `.claude/skills/`, `~/.claude/skills/`, `.agents/skills/`, `~/.agents/skills/`.
- Ajan **listeyi görür** (isim + `description`), içeriği **gerektiğinde `skill` aracıyla yükler** → bağlam şişmez.
- İzin: `permission.skill` (`allow`/`ask`/`deny`, `internal-*` gibi jokerler).

### 2) Araçlar
- Yerleşikler: `read`, `write`, `edit`, `bash`, `glob`, `grep`, `list`, `task` (alt-ajan), `skill` (+ TODO).
- Yeni araç 3 yolla eklenir; **bizim yolumuz = yerel plugin** (bkz. `plugins/README.md`).
- İzinler: `permission.bash/edit/read/external_directory` → `rm -rf*`, `mkfs*`, force-push = **deny**.

### 3) Ajanlar
- Primary: **Build** (tam yetki) + **Plan** (değişiklik yok). `Tab` ile geçiş.
- Subagent: **General / Explore / Scout** (`@` veya `task` aracıyla; paralel iş).
- Ajan başına `model`, `prompt`, `permission` tanımlanır.

### 4) Kurallar
- Proje: `AGENTS.md` · Global: `~/.config/opencode/AGENTS.md` · (uyumluluk: `CLAUDE.md`)
- `opencode.json` → `instructions: [...]` ile ek dosyalar da bağlama alınır.

### 5) Hafıza
- opencode'ta **otomatik uzun-dönem hafıza YOK** (oturum + otomatik compaction + `opencode stats`).
- Kalıcılık bilinçli kurulur: **AGENTS.md** (kurallar) + **beceriler** (usül) + **notlar**.
- Orkestrasyon hafızası (kim ne yaptı, hangi iş bitti) ayrı yürütülür.

## Genişletme sırası — "önce uzat, en son fork"

```
opencode.json (ayar) → AGENTS.md (kural) → SKILL.md (beceri) → plugins/ (yerel tool) → (yetmezse) fork
```
Fork yalnızca plugin API'sinin yapamadığı iş (UI paritesi, TUI davranışı) için.

## Geliştirme (self-improvement) döngüsü

1. **Gözlem/hata** — saha kullanımında yakalanan eksik
2. **Sınıfla** — kural mı (AGENTS.md) · bilgi mi (beceri) · yetenek mi (plugin/tool) · ayar mı (config)?
3. **Yaz** — ilgili katmana
4. **Test + kıyas** — aynı görevi tekrar koştur: doğru cevap · süre · token · gereksiz araç çağrısı
5. **Biriktir + sadeleştir** — kullanılmayan beceriyi at (kullanılmayan özellik geliştirilmez)

## Yol haritası

| Faz | İş | Kim |
|---|---|---|
| **0** | hedef makinede kur + 3 gerçek görevi koştur, kıyasla | Alp |
| **1** | Acıyan yerleri kural + beceri ince ayarıyla kapat (kod yok) | Doktor |
| **2** | Yalnız beceri+bash'in yetmediği yere **yerel plugin/tool** | Doktor |
| **3** | (Opsiyonel) UI paritesi için fork | Doktor |

## Depo yapısı

```
AGENTS.md            # kural katmanı
opencode.json        # sağlayıcı + izin ayarları
skills/*/SKILL.md    # 38 beceri
plugins/             # araç (tool) katmanı — kodlanacak
kur.sh               # offline kurulum
oc-dogrula.sh        # kurulum doğrulama
README.md            # kullanım
NASIL-CALISTIRILIR.md# adım adım + sorun giderme
DENEYIM-AKTARIM.md   # aider → opencode eşleme
MIMARI.md            # bu dosya
```

> `bin/` (185 MB opencode ikilisi) ve `env` (sırlar) **repoya girmez**; ikili ayrı paketle taşınır.
