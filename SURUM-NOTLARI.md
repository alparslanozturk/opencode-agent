# SÜRÜM NOTLARI — opencode ajan kiti

## 2026-09-15 — Compaction thrash düzeltmesi (Vaka 1 + Vaka 2)

**Ne değişti:**
- `engine/opencode.json`: `permission.webfetch/task/todowrite = "deny"` — baseline araç şeması
  21.1K → 13.1K karakter (ölçülen, ~%16 bağlam kazancı); `task` alt-agent'ların iç içe thrash riskini
  kapatır, `webfetch` zaten "dış ağa veri gönderme yok" kuralıyla çelişiyordu.
- `engine/AGENTS.md`: "Tek adım disiplini" (araç sonrası dur, plan metni üretme) ve "Çalışma dizini
  boşsa" (sessizce döngüye girme, açıkça söyle) kuralları eklendi.
- `NASIL-CALISTIRILIR.md`: kanıtlı kök neden (baseline ~%87 doluluk + araç-çağrısız yanıtta harness'in
  adım döngüsünü durdurmaması), canlıda denenebilecek teşhis adımları, context ölçüm adımı, dağıtım
  kontrolü (boş çalışma dizini ≠ kural yüklenmedi — global kurulum) eklendi.
- Rapor: `notlar/QWEN-COMPACTION-RAPOR.md`.

**Kök neden özet:** İki katmanlı. (1) 38 beceri listesi + yerleşik sistem promptu + araç şemaları,
boş bir dizinde bile ilk istekte 16k pencerenin ~%87'sini dolduruyor (gerçek istek gövdesi ölçülerek
doğrulandı). (2) Model araç çağırmayan bir yanıt döndürdüğünde opencode 1.18.30'un adım döngüsü
**durmuyor** — yerel bir mock LLM ile modelden bağımsız olarak yeniden üretildi (12 saniyede 178 adım,
üst sınır/bekleme yok). İkinci madde ikiliye gömülü bir harness hatası; repo düzeyinde düzeltilemez,
yalnız alanı büyütüp tetiklenme ihtimalini azaltabildik.

## 2026-09-14 — Faz -1 paketi

**Ne değişti:**
- **Motor/bilgi ayrımı:** kökteki `skills/` kaldırıldı. Yeni düzen:
  - `engine/` → **motor tarafı**: `AGENTS.md`, `opencode.json`, `plugins/` (opencode'un okuduğu çalışma ayarları)
  - `knowledge/` → **kurumsal hafıza**: `skills/approved/` (38 beceri), `runbooks/`, `incidents/`, `lessons-learned/`, `operations-notes/`, `architecture/`, `policy/`, `roadmap/`
  - Kural: **AI kendi kendine öğrenmez, öğrenme önerir** → yeni beceri `knowledge/skills/experimental/` (open **okumaz**) → insan onayı → `approved/` (open **okur**)
- **Yeni politika katmanı `knowledge/policy/`** (Faz -1 çıktısı):
  - `THREAT-MODEL.md` — varlıklar, aktörler, saldırı yüzeyleri, "v1 mutlak sınır: salt-okunur"
  - `PERMISSION-MATRIX.md` — 9 araç için allow/ask/deny önerisi + "kural atlanabilir / hook atlanamaz" tablosu
  - `AUDIT-FORMAT.md` — 17 alanlı JSONL (OTel GenAI adları), `prev_hash` zinciri, repo dışı konum
- **`knowledge/roadmap/PHASE0-ACCEPTANCE.md`** — Faz 0 kabul kriterleri (5 madde) + ölçüm + rapor şablonu
- **`knowledge/architecture/`** — ADR-0001 (`decisions/0001-v1-scope-and-guardrails.md`) + `consultations/` (2 tur çoklu-model danışma kaydı)
- `oc-dogrula.sh`: knowledge iskeleti artık **10 dizin** kontrol ediyor (`policy/` eklendi)

**Kurulum:** `tar xJf opencode-paket.tar.xz -C /root` → `env` doldur → `./kur.sh` → `opencode` (kısa ad `oc`)

**Sırada (Faz 0):** izin bloğunu `engine/opencode.json`'a uygula · audit hook plugin (`engine/plugins/`) · 3 gerçek salt-okunur görevle test → `PHASE0-ACCEPTANCE.md` şablonuyla rapor.
