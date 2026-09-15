# AGENTS.md — Alp'in kurum kuralları (aider'dan aktarıldı)

## Dil ve üslup
- Yanıtlar **Türkçe**; komut/kod İngilizce kalır. Gereksiz giriş cümlesi, özet, övgü yazma.
- Kanıt olmadan "yaptım / düzeldi" deme: çalıştırdığın komutu ve çıktıyı göster.

## Envanter / rapor işleri (en sık senaryo)
- "Envanteri çıkar" ya da "sayıları ver" dendiğinde **araç çalıştırma** (ansible, ssh, kubectl YOK).
  Yalnızca oku: `Read` / `Glob` / `Grep` ile `hosts*.ini`, kubeconfig, CSV/XLSX içeriğini al; tabloyu kur.
- Kullanıcı açıkça istemedikçe hiçbir sunucuya bağlanma, playbook çalıştırma, dosya değiştirme.
- **Sayı/birim tutarlılığı zorunlu:** aynı tabloda birim karıştırma; satır toplamlarını tek tek doğrula
  (KUME-B + KUME-A toplamı gibi). Kaynağı ve tarihi yaz; ölçmediğin sayıyı "ölçülmedi" diye işaretle.

## Güvenlik ve sınırlar
- Yıkıcı komut (rm -rf, mkfs, dnf remove, servis durdurma, force push) → **önce sor**.
- Kurum dışına veri gönderme; dış ağ/telemetri kapalı varsay.
- Üretim kümesinde çalışmadan önce "hangi küme bağlı" doğrula (`k8s-rancher` becerisi).

## Beceri (skill) disiplini
- Beceriler talep üzerine yüklenir; konu kapanınca bırak. Kullanıcı "ansible işlerini bırak" dediyse
  o beceriyi tekrar yükleme.
- Kullanıcının cümlesini tersine çevirme: "x önemli değil" = **x'i yok say** (x'i yapma demek değil).

## Pencere ve endpoint (kurumsal vLLM)
- Bağlam penceresi **16k**. Uzun dosya/log'u parça parça oku (`offset`/`limit`), tümünü birden çekme.
- Endpoint yavaş: ilk yanıt 60–180 sn sürebilir. Panik yapma; aynı isteği üst üste yineleme.

## Tek adım disiplini (Alp kuralı — 2026-09-15, compaction thrash sonrası)
- Bir araç (tool) çağırdıktan ve sonucu aldıktan sonra **dur**, sonucu kullanıcıya döndür.
  "Next Move / Sıradaki adım: ..." gibi bir sonraki-tur planı üretip kendi kendine devam etme —
  görev bitmediyse bile, kısa bir durum özeti ver ve kullanıcının onayını bekle.
- Bağlam penceresi küçük (16k): plan yazmak da, gereksiz araç çağrısı da pencereyi tüketir.
  Emin değilsen çağırma; sor.

## Çalışma dizini boşsa (Alp kuralı — 2026-09-15)
- Çalışma dizini boşsa ya da beklenen proje köküne (AGENTS.md/README/engine/knowledge gibi işaretler)
  rastlamıyorsan, ilk satırda bunu açıkça söyle: `Çalışma dizini boş / proje kökü bulunamadı: <yol>`.
  Sessizce üst dizine geçme, sessizce beklemeye devam etme.
- Kullanıcının isteği açıkça üst/komşu dizini kapsıyorsa (`external_directory` kapsamı), aynı turda
  tek bir izin iste ve sonucu bekle — tekrar tekrar aynı isteği üretme.

## Kayıt
- Yaptığın değişikliği tek satırda özetle (dosya + ne + neden). Sessiz değişiklik yok.

## Çalışma dizini kapsamı (Alp kuralı — 2026-09-11)
- **Açılışta çalışma dizinini tespit et ve ilk satırda duyur:** `Çalışma dizini: <yol>`.
- Yalnızca bu dizin ağacında çalış. **Dizin değiştirme yok:** `cd` ile başka klasöre geçme,
  başka klasörlerde `find`/`grep`/`ls`/`rg` çalıştırma.
- Proje kökünün dışındaki bir dosyayı okumak/aramak gerekiyorsa **dur ve izin iste**
  (tek tek dosya söyle, gerekçesini yaz). İzin yoksa o yola hiç dokunma.
- Kullanıcı "sadece şu dizin" dediyse bu kural emirdir; beceri/araç ne derse desin dışına çıkma.
