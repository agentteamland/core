---
name: save-learnings
description: "Sohbet sonunda öğrenilenleri kaydet. Proje özel bilgiler agent-memory'ye, genel bilgiler team repo'sundaki agent dosyasına yazılır ve otomatik push edilir."
argument-hint: "[agent-name]"
---

# /save-learnings Skill

## Amaç

Her sohbet sonunda çağrılır. Bu sohbette öğrenilen şeyleri (yeni pattern, anti-pattern, keşif, hata dersi) kalıcı hale getirir. Böylece sonraki sohbetlerde agent daha akıllı olur.

## Akış

### 1. Aktif Agent'ı Belirle

Argüman olarak agent adı verilmişse onu kullan. Verilmemişse, bu sohbette hangi agent ile çalışıldığını bağlamdan çıkar (hangi dosyalar düzenlendi, hangi dizinlere dokunuldu).

### 2. Sohbeti Analiz Et

Bu sohbette neler öğrenildi? Şu kategorilere göre tara:

- **İşe yarayan pattern'ler** — "Bunu şöyle yaptık ve iyi çalıştı"
- **İşe yaramayan pattern'ler** — "Bunu denedik ama sorun çıktı, şu yüzden"
- **Ortaya çıkan pattern'ler** — "Henüz kesin değil ama şu eğilim var"
- **Süreç iyileştirmeleri** — "Agent'ın workflow'unda şu adım eksikti / fazlaydı"
- **Yeni kurallar** — "Bundan sonra şunu her zaman yapmalıyız / yapmamalıyız"

### 3. Kullanıcıya Özetle ve Onayla

Bulunan öğrenmeleri kullanıcıya göster ve sor:

```
Bu sohbette şunları öğrendik:

1. [İşe yarayan] EF Core'da Include chain 3'ten fazla olunca projection kullanmak lazım
2. [Anti-pattern] Redis'te 1MB'den büyük value saklamak timeout'a neden oluyor
3. [Süreç] Consumer'lar kendi topology'lerini declare etmeli

Bunları kaydedeyim mi? Her biri için:
- Sadece bu proje (memory)
- Tüm projeler (team repo)
- Kaydetme (atla)
```

AskUserQuestion ile her öğrenme için seçenek sun.

### 4. Proje Memory'ye Yaz (proje özel olanlar)

Dosya: `.claude/agent-memory/{agent-name}-memory.md`

Yoksa oluştur. Varsa append et. Format:

```markdown
## {Tarih}

### İşe Yarayan
- {öğrenme} — Kanıt: {ne oldu}

### İşe Yaramayan
- {öğrenme} — Kanıt: {ne oldu}

### Ortaya Çıkan Pattern'ler
- {gözlem} — Henüz doğrulanmadı
```

### 5. Team Repo'ya Yaz (genel olanlar)

Agent dosyası symlink üzerinden düzenlenir — aslında `~/agent-teams/{team}/agents/{agent}.md` güncellenir.

Yapılacak güncelleme türleri:
- **Yeni kural** → agent dosyasındaki ilgili bölüme ekle
- **Yeni pattern** → ilgili children bölümüne ekle
- **Workflow güncellemesi** → workflow adımlarını güncelle

### 6. Team Repo'yu Push Et (genel güncelleme varsa)

```bash
cd ~/agent-teams/{team-name}
git add -A
git commit -m "learn: {kısa öğrenme özeti}"
git push
```

Kullanıcıya bildir: "Team repo güncellendi ve push edildi."

### 7. Journal'a Yaz (varsa)

Eğer core'un journal sistemi aktifse, öğrenmeleri journal'a da yaz — diğer agent'lar faydalanabilsin.

Dosya: `.claude/journal/{tarih}_{agent-name}.md`

```markdown
---
date: {tarih}
agent: {agent-name}
tags: [learning, {kategori}]
---

## Öğrenilenler

- {öğrenme listesi}

## Diğer Agent'lar İçin Notlar

- {varsa cross-cutting bilgiler}
```

## Önemli Kurallar

1. **Her sohbet sonunda çağrılabilir.** Zorunlu değil ama teşvik edilir.
2. **Kullanıcı onayı olmadan yazmaz.** Öğrenmeleri göster, onayla, sonra yaz.
3. **Git push otomatik.** Team repo güncellemesi varsa commit + push yapılır.
4. **Proje memory dosyası yoksa oluşturulur.** İlk sohbette boş başlar.
5. **Üzerine yazmaz, append eder.** Tarih başlığıyla eklenir.
6. **Hassas bilgi kontrolü.** Password, token, secret gibi bilgiler memory'ye yazılmaz.
