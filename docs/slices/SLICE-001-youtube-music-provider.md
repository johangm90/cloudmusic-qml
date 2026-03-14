# SLICE-001: YouTube Music Provider Support

**Status:** draft  
**Priority:** P1  
**Depends on:** ADR-001 (approved)  
**Agents:** spex-db, spex-backend, spex-frontend, spex-qa, spex-gitops  
**Created:** 2026-03-13  

---

## Problem Statement

Os utilizadores de cloudmusic-qml estão limitados ao catálogo da NetEase Cloud Music, um serviço primariamente acessível no mercado chinês. Utilizadores fora da China — incluindo a diáspora e entusiastas Linux internacionais — não têm acesso a este catálogo sem VPN, e mesmo com VPN enfrentam restrições geográficas. YouTube Music tem catálogo global, não tem restrições regionais na maioria dos países, e os seus utilizadores esperam poder aceder à sua biblioteca a partir de qualquer cliente de música. Este slice adiciona YouTube Music como segundo provedor nativo, permitindo a qualquer utilizador mudar de provedor sem sair da app, preservando playlists, favoritos e histórico separados por provedor.

---

## Scope

### In scope
- Pesquisa de músicas, álbuns e artistas no YouTube Music via UI de Search existente
- Reprodução de músicas do YouTube Music via proxy local (`http://127.0.0.1:39876/play/youtube/{id}/{quality}`)
- Persistência de favoritos com `source = 'youtube'` em `liked_songs`
- Persistência de histórico com `source = 'youtube'` em `recently_played`
- Selector de provedor activo na SettingsPage e/ou na Search page
- Preferência de provedor activo persistida em SQLite
- Refactoring do código NetEase para implementar o trait `MusicProvider` (ADR-001)
- Migração do proxy URL schema: `/play/{id}/{quality}` → `/play/{provider}/{id}/{quality}`
- Actualização de `CatalogService.js` e `PlaybackService.js` para multi-provedor
- Adaptação das páginas Album, Artist e NowPlaying para mostrar a fonte da canção
- Zero regressão nas funcionalidades NetEase existentes

### Out of scope
- Login/autenticação com conta YouTube Music (OAuth)
- Playlists síncronizadas da cloud YouTube Music
- Download offline de músicas do YouTube Music
- Suporte a vídeos (apenas áudio)
- Suporte a qualquer terceiro provedor (ex.: Spotify, SoundCloud) — este slice define a arquitectura, não implementa todos os provedores
- Recomendações personalizadas ou feed do YouTube Music
- Suporte a podcasts ou conteúdo não-musical do YouTube Music

---

## Domain Context

**Primary bounded context:** Music Streaming / Provider Integration  
**Secondary bounded contexts touched:** Local Persistence (SQLite), UI Presentation (QML pages), Proxy Routing (tiny_http)

Este slice introduz a camada de abstracção multi-provedor definida em ADR-001. É o slice fundacional para toda a arquitectura multi-provedor: todos os slices futuros de provedores dependem das interfaces e convenções aqui estabelecidas.

---

## User Story / Scenario

```
As a utilizador de Ubuntu Touch,
I want poder pesquisar e ouvir músicas do YouTube Music na mesma app
  que uso para ouvir NetEase Cloud Music,
so that não preciso de mudar de app ou usar o browser para aceder
  ao catálogo global do YouTube Music.
```

**Scenario walkthrough:**
1. Utilizador abre a app; por omissão o provedor activo é NetEase (sem quebra de comportamento existente).
2. Utilizador vai a Settings e selecciona "YouTube Music" como provedor activo.
3. A preferência é guardada em SQLite e a app mostra indicação visual do provedor activo.
4. Utilizador vai à página Search e pesquisa "Bohemian Rhapsody".
5. Os resultados mostram músicas do YouTube Music com o ícone/badge "YT" ou equivalente.
6. Utilizador toca numa música; o QML MediaPlayer recebe `http://127.0.0.1:39876/play/youtube/{videoId}/128k`.
7. O proxy resolve a URL de stream real, re-proxia o áudio, e a reprodução começa em ≤ 3s.
8. A música aparece em "Recently Played" com `source = 'youtube'`.
9. Utilizador clica em "Gosto" — a música é guardada em `liked_songs` com `source = 'youtube'`.
10. Utilizador volta a Settings e muda para NetEase — todas as funcionalidades NetEase funcionam exactamente como antes.

---

## API Surface (draft)

### Proxy local — nova rota

```
GET http://127.0.0.1:39876/play/{provider}/{id}/{quality}
  Parâmetros:
    provider: "netease" | "youtube"
    id:       string (song ID ou YouTube videoId)
    quality:  "low" | "medium" | "high" (normalizado; mapeado por provedor)
  Resposta:  stream de áudio (chunked transfer ou redirect)
  Erros:
    404 — provedor desconhecido
    502 — falha ao resolver URL de stream
    503 — serviço do provedor indisponível
```

### Trait Rust `MusicProvider` (contrato interno)

```rust
// DRAFT — implementação final é responsabilidade de spex-backend
trait MusicProvider: Send + Sync {
    fn provider_id(&self) -> &'static str;  // "netease" | "youtube"
    fn search(&self, query: &str, page: u32) -> Result<Vec<Song>, ProviderError>;
    fn stream_url(&self, id: &str, quality: Quality) -> Result<String, ProviderError>;
    fn album(&self, id: &str) -> Result<Album, ProviderError>;
    fn artist(&self, id: &str) -> Result<Artist, ProviderError>;
    fn top_songs(&self, artist_id: &str) -> Result<Vec<Song>, ProviderError>;
    fn supported_qualities(&self) -> Vec<Quality>;
}

enum Quality { Low, Medium, High }
```

### QML — novo campo em objectos Song

```javascript
// Todos os objectos Song passam a incluir:
{
  "id": "...",
  "name": "...",
  "artist": "...",
  "album": "...",
  "source": "youtube" | "netease",   // NOVO — obrigatório
  "streamUrl": "http://127.0.0.1:39876/play/{source}/{id}/{quality}"
}
```

### QML — AppContext — novo campo de provedor activo

```javascript
// AppContext.js
property string activeProvider: "netease"  // persistido em SQLite
```

---

## Domain Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `ProviderChanged` | produced | Emitido quando o utilizador muda o provedor activo em Settings; carrega `{from, to}` |
| `SongPlaybackStarted` | produced | Já existente; passa a incluir campo `source` no payload |
| `SongLiked` | produced | Já existente; passa a incluir campo `source` no payload |

---

## Data Requirements

- **New entities / tables:** `provider_settings` — tabela com uma linha única (ou key-value) para persistir `active_provider TEXT NOT NULL DEFAULT 'netease'`
- **Existing entities modified:**
  - `songs` — verificar que `source` já existe com `NOT NULL`; se ausente, adicionar via migração
  - `liked_songs` — verificar constraint `UNIQUE(sid, source)`; confirmar que `source = 'youtube'` não colide com NetEase
  - `recently_played` — idem
- **Migrations required:** yes — migração incremental em `Database.js` para criar `provider_settings` e validar `source NOT NULL` nas tabelas existentes
- **Sensitive data:** Credenciais/tokens YouTube (se aplicável via YouTube Data API v3) — NÃO devem ser hardcoded; avaliar abordagem de extracção sem API key (ver Open Questions)

---

## Dependent Artifacts

| Artifact ID | Type | Provided by |
|-------------|------|-------------|
| ADR-001 | adr | spex-architect |
| T001-1 | db_migration | spex-db |
| T001-2 | rust_implementation | spex-backend |
| T001-3 | proxy_routing | spex-backend |
| T001-4 | qml_services | spex-frontend |

---

## Task Decomposition

### Wave 1 — Foundation (DB + Backend Rust interface)
_Prerequisite: ADR-001 approved. Wave 2 cannot start until T001-1 AND T001-2 are done._

| Task ID | Title | Agent | Inputs | Output Artifact |
|---------|-------|-------|--------|----------------|
| T001-1 | Migração de schema + tabela `provider_settings` | spex-db | ADR-001, PRD schema | `db_migration_v2.sql` + actualização de `Database.js` |
| T001-2 | Trait `MusicProvider` em Rust + refactoring NetEase + implementação YouTube Music | spex-backend | ADR-001, T001-1 | `src/providers/mod.rs`, `src/providers/netease.rs`, `src/providers/youtube.rs` |

**T001-1 detail (spex-db):**
- Migração incremental em `Database.js` (incrementar versão de schema)
- Criar tabela `provider_settings (id INTEGER PRIMARY KEY, active_provider TEXT NOT NULL DEFAULT 'netease')`
- Inserir linha inicial `(1, 'netease')` se não existir
- Verificar e garantir `source TEXT NOT NULL` em `songs`, `liked_songs`, `recently_played`
- Verificar constraint `UNIQUE(sid, source)` em `liked_songs` e `recently_played`
- Sem recreação de tabelas — apenas ALTER TABLE e CREATE TABLE IF NOT EXISTS

**T001-2 detail (spex-backend):**
- Definir trait `MusicProvider` com os métodos do API Surface acima
- Refactorar código NetEase existente para implementar `MusicProvider` (sem quebra de comportamento)
- Implementar `YouTubeProvider` (ver Open Questions sobre método de extracção de stream)
- Implementar `ProviderRegistry` — mapa `provider_id -> Box<dyn MusicProvider>`
- Unit tests para ambos os provedores (mock de HTTP)

---

### Wave 2 — Integration (Proxy + Services QML)
_Prerequisite: T001-1 + T001-2 done._

| Task ID | Title | Agent | Inputs | Output Artifact |
|---------|-------|-------|--------|----------------|
| T001-3 | Routing no proxy local para multi-provedor | spex-backend | T001-2 | `src/proxy.rs` (router actualizado) |
| T001-4 | Actualizar `CatalogService.js` e `PlaybackService.js` para multi-provedor | spex-frontend | T001-3, T001-1 | `qml/services/CatalogService.js`, `qml/services/PlaybackService.js` |

**T001-3 detail (spex-backend):**
- Actualizar handler do `tiny_http` para o novo esquema `/play/{provider}/{id}/{quality}`
- Manter retrocompatibilidade temporária com `/play/{id}/{quality}` via redirect ou fallback para `netease` (a remover numa release posterior)
- Delegar ao `ProviderRegistry` para resolver a URL de stream
- Testar com `curl` para ambos os provedores

**T001-4 detail (spex-frontend):**
- Actualizar `CatalogService.js` para incluir campo `source` em todos os objectos Song retornados
- Actualizar `PlaybackService.js` para construir URLs de proxy com `{provider}` (ex.: `/play/youtube/...` ou `/play/netease/...`)
- Actualizar `AppContext.js` com `property string activeProvider` lido de SQLite via `Database.js`
- Garantir que chamadas existentes ao proxy NetEase continuam a funcionar (sem regressão)

---

### Wave 3 — UI + Settings
_Prerequisite: T001-4 done._

| Task ID | Title | Agent | Inputs | Output Artifact |
|---------|-------|-------|--------|----------------|
| T001-5 | Selector de provedor na UI (SettingsPage + indicador em Search) | spex-frontend | T001-4, DesignTokens.js | `qml/ui/SettingsPage.qml` (actualizado), `qml/ui/Search.qml` (actualizado) |
| T001-6 | Adaptar páginas Album, Artist e NowPlaying para mostrar fonte da canção | spex-frontend | T001-4, DesignTokens.js | `qml/ui/Album.qml`, `qml/ui/Artist.qml`, `qml/ui/NowPlaying.qml` (actualizados) |

**T001-5 detail (spex-frontend):**
- Adicionar selector (OptionSelector ou equivalente Lomiri) na SettingsPage para escolher entre "NetEase Cloud Music" e "YouTube Music"
- Persistir a escolha via `Database.js` (tabela `provider_settings`)
- Mostrar indicador visual do provedor activo no cabeçalho da Search page (sem alterar o layout)
- Usar exclusivamente `DesignTokens.js` para cores/espaçamentos — zero cores hardcoded
- Loading spinner obrigatório durante a mudança de provedor

**T001-6 detail (spex-frontend):**
- Adicionar badge/label de "fonte" (ex.: "YouTube Music" ou "NetEase") nas páginas Album, Artist e NowPlaying
- Badge deve usar tokens de cor de `DesignTokens.js`; proposta: adicionar `sourceColors` ao DesignTokens se necessário
- NowPlaying deve mostrar o ícone/nome do provedor da canção em reprodução
- Não alterar layouts existentes de forma destrutiva — apenas adições

---

### Wave 4 — QA + GitOps
_Prerequisite: T001-5 + T001-6 done._

| Task ID | Title | Agent | Inputs | Output Artifact |
|---------|-------|-------|--------|----------------|
| T001-7 | Test plan + verificação de todos os ACs + regressão NetEase | spex-qa | Todos os artefactos T001-1 a T001-6 | `docs/qa/SLICE-001-test-report.md` |
| T001-8 | Feature branch + PR + CHANGELOG entry | spex-gitops | T001-7 (QA sign-off) | PR no GitHub, `CHANGELOG.md` actualizado |

**T001-7 detail (spex-qa):**
- Verificar cada AC da lista abaixo (pass/fail explícito)
- Executar regressão completa das 11 funcionalidades core NetEase
- Verificar `clickable build` sem warnings/erros novos
- Verificar consistência de versões (`Cargo.toml`, `manifest.json`, `Main.qml`)
- Reportar em `docs/qa/SLICE-001-test-report.md`
- **QA sign-off é bloqueante para T001-8**

**T001-8 detail (spex-gitops):**
- Criar feature branch `feature/SLICE-001-youtube-music-provider`
- Validar mensagens de commit (Conventional Commits)
- Abrir PR com descrição completa referenciando SLICE-001 e ADR-001
- Adicionar entrada em `CHANGELOG.md` (secção `[Unreleased]`, tipo `feat`)

---

## Acceptance Criteria

- [ ] **AC1 — Pesquisa YouTube Music:** O utilizador pode pesquisar músicas na Search page com o provedor "YouTube Music" activo e receber resultados relevantes em ≤ 5 segundos em Wi-Fi estável.

- [ ] **AC2 — Reprodução via proxy local:** A reprodução de uma música do YouTube Music usa exclusivamente a URL `http://127.0.0.1:39876/play/youtube/{id}/{quality}`. Nenhuma URL de CDN externo (ex.: `googlevideo.com`, `youtube.com`) é passada directamente ao QML MediaPlayer.

- [ ] **AC3 — Latência de arranque de reprodução:** 95% das músicas do YouTube Music começam a reproduzir em ≤ 3 segundos após o utilizador tocar "Play" em Wi-Fi estável (medido em dispositivo real ou emulador ARM).

- [ ] **AC4 — Persistência de favoritos:** Marcar uma música do YouTube Music como favorita cria um registo em `liked_songs` com `source = 'youtube'`. Após fechar e reabrir a app, a música continua nos favoritos.

- [ ] **AC5 — Persistência de histórico:** Ouvir uma música do YouTube Music cria um registo em `recently_played` com `source = 'youtube'`. O registo persiste entre sessões.

- [ ] **AC6 — Selector de provedor persistido:** O utilizador pode mudar o provedor activo em Settings. A preferência persiste após fechar e reabrir a app (lida de `provider_settings` em SQLite).

- [ ] **AC7 — Indicação visual de provedor:** As páginas Search, NowPlaying, Album e Artist mostram claramente de qual provedor é o conteúdo em exibição. O badge/label usa cores/tokens de `DesignTokens.js` (nenhuma cor hardcoded).

- [ ] **AC8 — Zero regressão NetEase:** Com o provedor activo definido como "NetEase", todas as funcionalidades existentes (pesquisa, reprodução, letras, playlists, favoritos, historial, downloads, artistas, álbuns, fila) funcionam exactamente como antes deste slice.

- [ ] **AC9 — Sem URLs CDN directas no QML:** Auditoria do código QML confirma que nenhum ficheiro `.qml` ou `.js` constrói ou usa URLs de domínios externos (ex.: `youtube.com`, `ytimg.com`, `163.com`). Todas as URLs de media passam pelo proxy local.

- [ ] **AC10 — Build limpo:** `clickable build` completa sem novos warnings de compilação Rust (nível `deny(warnings)`) e sem erros de runtime QML nos logs.

- [ ] **AC11 — Estados de erro tratados:** Se o YouTube Music estiver indisponível ou a pesquisa falhar, a UI mostra uma mensagem de erro clara (não crash, não spinner infinito). O timeout do `RequestBus.js` (30s) é respeitado.

- [ ] **AC12 — Tema visual correcto:** Todos os novos elementos UI (selector de provedor, badges, indicadores) funcionam correctamente nos temas Ambiance, SuruDark e System, sem artefactos visuais ou cores incorrectas.

---

## Dependencies & Risks

### Dependências Externas

| Dependência | Tipo | Risco |
|-------------|------|-------|
| Método de extracção de stream YouTube | CRÍTICO | Ver Open Question OQ-1 |
| `yt-dlp` ou biblioteca equivalente em Rust | Técnica | Compilação ARM/MUSL no clickable — ver OQ-2 |
| YouTube Data API v3 (opcional) | Técnica | Requer API key — ver OQ-3 |
| `invidious` / `piped` como proxy intermédio | Alternativa | Dependência de instâncias terceiras — ver OQ-4 |

### Riscos Técnicos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Violação dos ToS YouTube | Alta | Alto (app removida das stores) | OQ-1: definir abordagem legal antes de Wave 1 |
| `yt-dlp` não compila em ARM/MUSL | Média | Alto (feature inviável) | OQ-2: prototipar em T001-2 antes de comprometer |
| Regressão NetEase no refactoring do trait | Média | Alto (quebra funcionalidade core) | Testes de regressão explícitos em T001-7 |
| Latência de stream YouTube > 3s | Média | Médio (AC3 falha) | Testar em dispositivo real; considerar pre-buffering |
| Mudança do esquema de URL do proxy quebra clientes | Baixa | Alto | Retrocompatibilidade temporária em T001-3 |
| Qualidades de áudio inconsistentes entre provedores | Baixa | Baixo | `supported_qualities()` no trait normaliza o mapeamento |

---

## Open Questions (bloqueantes para Wave 1)

> **As seguintes questões DEVEM ter resposta humana antes de iniciar T001-2 (Wave 1).**

**OQ-1 — Método de extracção de stream YouTube Music [BLOQUEANTE]**  
Como extrair a URL de stream de áudio do YouTube Music de forma programática em Rust?  
Opções:
- (a) `rustube` (crate Rust puro) — verificar suporte a YouTube Music vs YouTube standard
- (b) `yt-dlp` como subprocess — verificar se compila/está disponível no ambiente clickable ARM
- (c) `piped` / `invidious` API pública — sem dependência binária, mas depende de instâncias terceiras
- (d) YouTube Data API v3 oficial — requer API key pública no código  
**Decisão necessária:** qual abordagem é aceitável do ponto de vista legal, técnico e de packaging?

**OQ-2 — Compilação de dependências no toolchain clickable [BLOQUEANTE]**  
Qualquer nova crate Rust ou binário externo (ex.: `yt-dlp`) deve compilar no toolchain ARM usado pelo `clickable build`. Deve prototipar-se a compilação antes de comprometer com a abordagem escolhida em OQ-1.

**OQ-3 — Postura legal e ToS [BLOQUEANTE]**  
Usar YouTube Music sem autenticação e com extracção de streams pode violar os Termos de Serviço da Google. O maintainer (Johan Guerreros) deve tomar uma decisão explícita sobre a postura legal do projecto antes de desenvolver a feature.

**OQ-4 — Níveis de qualidade YouTube Music**  
NetEase usa `96k/160k/320k`. YouTube Music usa outros bitrates. Definir o mapeamento `Quality::Low/Medium/High` → bitrate YouTube antes de T001-2.

---

## Definition of Done

Baseado nos Acceptance Standards do PRD:

- [ ] Feature funciona em dispositivo real Ubuntu Touch (ou emulador ARM verificado)
- [ ] Todos os 12 ACs estão verificados e passam (reportado em `docs/qa/SLICE-001-test-report.md`)
- [ ] Zero regressões nas 11 funcionalidades core NetEase
- [ ] Todos os estados de erro estão tratados (sem crashs, sem spinners infinitos)
- [ ] Dados YouTube persistem em SQLite após restart da app
- [ ] UI respeita tema Ambiance/SuruDark/System sem cores hardcoded
- [ ] Sem memory leaks óbvios (sinais Rust→QML desconectados ao destruir componentes)
- [ ] `clickable build` completa sem novos warnings Rust nem erros QML
- [ ] Versões consistentes em `Cargo.toml`, `manifest.json` e `Main.qml`
- [ ] OQ-1, OQ-2 e OQ-3 têm resposta explícita documentada
- [ ] PR aprovado com feature branch, Conventional Commits e entrada em CHANGELOG
- [ ] spex-qa emitiu QASignOff formal antes do merge
