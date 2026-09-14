# SÜRÜM NOTLARI — opencode ajan kiti

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
