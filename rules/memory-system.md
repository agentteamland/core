# Memory & Journal Sistemi Kuralları

## İki Katmanlı Hafıza

### Proje Memory (proje özel)
**Konum:** `.claude/agent-memory/{agent-name}-memory.md`

Her projede, her agent'ın kendi memory dosyası olabilir. Bu dosya o projede öğrenilenleri saklar. Agent sohbet başında bu dosyayı okur.

**Kurallar:**
- Agent sohbet başında kendi memory dosyasını okumalı (varsa)
- Sadece `/save-learnings` ile güncellenir (elle düzenleme de mümkün)
- Proje bazlı — farklı projelerde farklı memory'ler
- Format: tarih başlıklı, kategorize (işe yarayan/yaramayan/ortaya çıkan)

### Team Bilgi Tabanı (global)
**Konum:** `~/agent-teams/{team}/agents/{agent}.md`

Agent'ın tüm projelerde geçerli olan bilgisi. Nadiren değişir ama her projeden öğrenilenler buraya da eklenebilir.

**Kurallar:**
- `/save-learnings` ile "tüm projeler" seçilirse güncellenir
- Güncelleme sonrası otomatik git commit + push
- Bu dosya symlink üzerinden `~/.claude/agents/` altından erişilir

## Journal (agent'lar arası paylaşım)

**Konum:** `.claude/journal/{tarih}_{agent-name}.md`

Agent'lar arası bilgi paylaşımı. Bir agent bir şey keşfettiğinde journal'a yazar, diğer agent'lar sonraki sohbetlerde okur.

**Kurallar:**
- Her agent journal'ı okuyabilir
- Her agent kendi adıyla journal'a yazabilir
- Journal dosyaları silinmez (tarihsel kayıt)
- Tarih bazlı dosya adı: `2026-04-13_api-agent.md`
- Journal brainsstorm dosyalarından farklıdır — journal kısa notlar, brainstorm uzun tartışmalar

## Agent Başlangıç Rutini

Her sohbet başında agent şu dosyaları okumalı (varsa):

1. Kendi agent dosyası (team'den, symlink üzerinden)
2. Proje memory: `.claude/agent-memory/{agent-name}-memory.md`
3. Son journal kayıtları: `.claude/journal/` (son 5-10 kayıt)
4. Proje özel kurallar: `.claude/docs/coding-standards/{app}.md`

## Sohbet Sonu Rutini

Her sohbet sonunda `/save-learnings` çağrılması teşvik edilir. Bu:
1. Sohbetten öğrenilenleri çıkarır
2. Kullanıcı onayıyla proje memory'ye ve/veya team repo'ya yazar
3. Journal'a not düşer
4. Team repo güncellendiyse otomatik push eder
