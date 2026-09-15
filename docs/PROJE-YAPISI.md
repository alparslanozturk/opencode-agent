# Proje Yapısı — Ne Nereye Konur

Alp'in kuralı (2026-09-15): *"Hazırladığım şeyler, yetenekler ve hafıza gibi özellikler projenin içinde gömülü olsun;
hepsine umumi olan şeyleri ayrı (global) yerde yaparım. Tüm çalışmalar çalışma alanında olabilir."*

opencode bu kuralı **birebir** destekliyor. Kaynak: opencode docs (rules / skills / commands / agents / config).

## Temel ilke

- **Global** (`~/.config/opencode/…`) = **her dizinde** geçerli. `kur.sh` bunu kurar.
- **Proje** (`<proje>/…`) = o dizinde **ve alt dizinlerinde** geçerli.
- İkisi **birleşir (additive)** — proje dosyası global'i **silmez**, üstüne eklenir.
- Proje tarafı, açılış dizininden **git worktree köküne** kadar yukarı taranır → proje köküne koymak yeterlidir.
- Kalıcılık için **yazılı** olmalı: sohbette söylenen şey oturumla gider, dosyaya yazılan kalır.

## Yerleşim tablosu

| Ne | Global (her proje) | Proje (o dizin) |
|---|---|---|
| Kural / hafıza | `~/.config/opencode/AGENTS.md` | `<proje>/AGENTS.md` |
| Ayar / izin | `~/.config/opencode/opencode.json` | `<proje>/opencode.json` |
| Beceri (skill) | `~/.config/opencode/skills/<ad>/SKILL.md` | `<proje>/.opencode/skills/<ad>/SKILL.md` |
| Komut | `~/.config/opencode/commands/<ad>.md` | `<proje>/.opencode/commands/<ad>.md` |
| Agent | `~/.config/opencode/agent/<ad>.md` | `<proje>/.opencode/agent/<ad>.md` |
| Veri / üretim | — | proje içi normal klasörler (`inventories/`, `baseline/`, `reports/`) |
| Claude Code uyumluluğu | `~/.claude/CLAUDE.md`, `~/.claude/skills/` | `CLAUDE.md`, `.claude/skills/` |
| Ek uyumluluk | `~/.agents/skills/` | `.agents/skills/` |

Notlar:
- Skill adı klasör adıyla **aynı** olmalı (`^[a-z0-9]+(-[a-z0-9]+)*$`); frontmatter'da `name` + `description` zorunlu.
- Skill'ler **talep üzerine** yüklenir: agent önce sadece ad+açıklama görür, gerekince `skill({name})` ile tam içeriği okur → bağlam şişmez.
- `opencode.json`'daki `instructions: [...]` listesi **eklemelidir** (AGENTS.md'ye ilave dosyalar/glob'lar).

## Hafıza (memory) karşılığı

opencode'da Claude Code'daki `#` ile hafızaya ekleme kısayolu **yok**. Kalıcı hafıza = **dosya**:

1. **En basit:** `<proje>/AGENTS.md` içinde bir `## Proje notları` bölümü.
   Agent'a *"bunu AGENTS.md'deki proje notlarına ekle"* dediğinde oraya yazar, sonraki açılışta okunur.
2. **Ayrı dosya:** `<proje>/PROJE-NOTLAR.md` + `<proje>/opencode.json`:
   ```json
   { "$schema": "https://opencode.ai/config.json", "instructions": ["PROJE-NOTLAR.md"] }
   ```
3. Aynı mantık **global** hafıza için: `~/.config/opencode/AGENTS.md` (kur.sh'ın kurduğu dosya; elle düzenlemek
   yerine `engine/AGENTS.md` kaynağı güncellenir).

## Örnek proje iskeleti

```
~/ansible/dns-ntp-splunk/
├─ AGENTS.md                  # projeye özel kurallar + notlar  (global'e EKLENİR)
├─ opencode.json              # (opsiyonel) instructions / izin ince ayarı
├─ .opencode/
│  ├─ skills/<ad>/SKILL.md    # sadece bu projede geçerli yetenek
│  └─ commands/<ad>.md        # sadece bu projede geçerli komut
├─ inventories/               # envanterler burada (proje içi → izin kapısı çıkmaz)
├─ playbooks/
├─ roles/
├─ group_vars/
└─ baseline/                  # ölçüm/rapor çıktıları
```

Kullanım: `cd ~/ansible/dns-ntp-splunk && oc`

## "Umumi" olunca ne olur

Projede olgunlaşan beceri/kural **global'e terfi eder**:
`<proje>/.opencode/skills/<ad>/` → paketin `knowledge/skills/approved/<ad>/` altına alınır → `kur.sh` ile
kurulur → **tüm projelerde** hazır olur. (Bu taşıma bir **Doktor** kalemidir; proje tarafı Alp'in çalışma alanında kalır.)

## Hızlı doğrulama

- Agent'a sor: *"Şu an hangi kural dosyaları yüklendi?"* (payload'da `Instructions from: <yol>` satırları olarak görünür).
- Proje kuralı uygulanmıyorsa kontrol: dosya adı `AGENTS.md` mi? doğru dizinde mi (proje kökü)? git worktree içinde mi?
