# Aider tecrübesi → opencode karşılığı

Aider fork'unda 15 fazda öğrendiğimiz her şeyin opencode'daki durumu.

## Doğrudan aktarıldı (bu pakette var)
| Aider'daki çalışma | opencode'da karşılığı | Durum |
|---|---|---|
| 38 beceri (`aider/beceriler/*/SKILL.md`) | `~/.config/opencode/skills/*/SKILL.md` — **aynı frontmatter (`name`+`description`)** | ✅ birebir kopya |
| Proje kuralları / davranış rehberi | `~/.config/opencode/AGENTS.md` (CLAUDE.md de okunuyor) | ✅ |
| Envanter işinde "araç çalıştırma, sadece oku" dersi (Canlı Test #3 / T-04) | AGENTS.md kuralı + `permission` (bash=ask) | ✅ |
| Beceri tetikleme disiplini (B-20/T-03: "envanter" kelimesini tetikleyiciden çıkarma) | Beceriler artık **talep üzerine** yükleniyor; description'lar aynen taşındı | ✅ (daha iyi: otomatik tetikleme yok) |
| Uzun yanıt/endpoint yavaşlığı (T-01/T-02: 180 sn bekleme, erken pes etme) | `provider.options.timeout=900000`, `headerTimeout=300000`, `chunkTimeout=180000` | ✅ ayarlandı |
| 16k pencere bilgisi | `models.<m>.limit = {context: 16384, output: 4096}` | ✅ bildirildi |
| Yıkıcı komut koruması | `permission.bash`: `rm -rf *` / `mkfs*` / force push = **deny**, diğerleri **ask** | ✅ |

## Çevirici (cc'deki `cevirici/`) — **GEREKMİYOR**
opencode zaten OpenAI uyumlu konuşuyor; kurum ucu da OpenAI uyumlu → aradan çevirici katmanı yok.
(Bu, cc paketindeki en kırılgan parçayı gereksiz kılıyor.)

## Aktarılamayan / açık kalanlar
| Aider'daki özellik | Neden yok | Ne zaman gerekir |
|---|---|---|
| Elle 16k token bütçesi + araç şeması kırpma | opencode'un kendi bağlam yönetimi var; bizim ince ayarımız taşınmadı | Denemede bağlam taşması görülürse → TS plugin |
| ~~Türkçe arayüz / çevirisi~~ | **KAPSAM DIŞI** — Alp (16:44): "türkçeleştirme derdim yok, aynı dilde devam edebiliriz" | ❌ kapandı, iş yok |
| Glif/ASCII güvenliği (`guvenli()`) | opencode'un TUI'ı kendi glif setini kullanıyor | Tofu görülürse → tema/fork |
| Yapıştırma (paste) kısayolu + CR düzeltmesi | Farklı TUI motoru | Kullanınca rahatsız ederse → bildir |
| `/beceri-uret` gibi komutlar | opencode'da plugin/command ile yapılır | İhtiyaç doğarsa → plugin |
| Onay ekranı numaralandırması (CC paritesi) | TUI içinde | UI işi sırasında |

## Sıradaki adım
1. hedef makinede `./kur.sh && opencode` → aynı 3 görevi koştur, **fork ile kıyasla**: doğru cevap · süre · token · gereksiz araç çağrısı.
2. Sonuç iyiyse: yukarıdaki "açık kalanlar" listesinden hangisi canımızı yakıyorsa **plugin** yazarız.
3. Plugin de yetmezse (UI paritesi) → fork'a kod. **Not: çeviri/Türkçeleştirme iş kalemi DEĞİL (Alp, 16:44).**

## 2026-09-14 — Bilgi katmanı ayrıldı (`knowledge/`)

Motor ile bilgi ayrıldı: `engine/` = opencode ayarı/kuralı (güncellenebilir), `knowledge/` = git tabanlı bilgi deposu (kalıcı).
Aider'daki "beceri kütüphanesi" fikri genişletildi:

| Aider'da | opencode'da (bu depo) |
|---|---|
| `aider/beceriler/*/SKILL.md` | `knowledge/skills/approved/*/SKILL.md` |
| (yoktu) | `knowledge/runbooks/` · `incidents/` · `lessons-learned/` · `operations-notes/` |
| (yoktu) | `knowledge/architecture/decisions/` (ADR) · `roadmap/` |
| (yoktu) | onay kapısı: `generated/` → `experimental/` → `approved/` |
