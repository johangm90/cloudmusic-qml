# ADR-001: Multi-Provider Music Architecture

**Date:** 2026-03-13  
**Status:** Proposed  
**Deciders:** spex-architect, Johan Guerreros (human owner)

---

### Context

cloudmusic-qml foi construído assumindo NetEase Cloud Music como único provedor de streaming. O esquema de base de dados já inclui um campo `source TEXT NOT NULL` em todas as tabelas de dados musicais — evidência de intenção de design multi-provedor — mas a arquitectura de runtime não suporta ainda múltiplos provedores: o proxy local responde apenas a um único conjunto de endpoints NetEase, o módulo Rust não tem abstracção de provedor, e os serviços QML constroem URLs assumindo sempre NetEase.

**Forças que tornam esta decisão necessária agora:**

1. **SLICE-001 (YouTube Music)** é o primeiro pedido concreto de um segundo provedor. Sem uma arquitectura definida, cada novo provedor implicará mudanças cirúrgicas e potencialmente destrutivas em todo o stack.
2. **Risco de fragmentação de dados:** sem uma interface comum, playlists e favoritos de provedores diferentes podem colidir em tabelas que não foram desenhadas para os distinguir.
3. **Prazo de sustentabilidade:** o campo `source` existe mas não é enforced em runtime — qualquer bug pode inserir registos sem `source` ou com `source` errado, corrompendo o historial do utilizador.
4. **Open Question #5 do PRD** exige explicitamente um ADR antes de aceitar features que assumam NetEase como único provedor.

**Restrições do sistema:**
- Stack Rust + QML sobre Ubuntu Touch / Lomiri; sem Node.js, sem servidor remoto próprio.
- O proxy local (`tiny_http` em `127.0.0.1:39876`) é o único ponto de entrada de streaming para o QML MediaPlayer — este contrato não pode ser quebrado.
- `clickable build` deve continuar a funcionar; sem dependências que requeiram glibc recente ou tooling externo ao ambiente de build existente.
- A base de dados SQLite é gerida pelo `QtQuick.LocalStorage` no lado QML; Rust não acede directamente ao SQLite.

---

### Problem Statement

Deve decidir-se como estruturar a camada de abstracção de provedor de música no backend Rust e no proxy local de modo a suportar N provedores simultaneamente, sem quebrar o contrato `http://127.0.0.1:39876/play/{id}/{quality}` que o QML MediaPlayer consome.

---

### Alternatives Considered

#### Option A: Trait `MusicProvider` em Rust com routing por prefixo no proxy

Cada provedor implementa um trait Rust comum (`MusicProvider`). O proxy local estende o seu esquema de URL para incluir o provedor como segmento: `http://127.0.0.1:39876/play/{provider}/{id}/{quality}`. O `Router` no processo `tiny_http` selecciona a implementação correcta com base no segmento `{provider}`.

```
Trait MusicProvider:
  - search(query, page) -> Vec<Song>
  - stream_url(id, quality) -> String
  - album(id) -> Album
  - artist(id) -> Artist
  - top_songs(artist_id) -> Vec<Song>

Implementações:
  - NeteaseProvider  (código existente refactorado)
  - YouTubeProvider  (nova implementação — SLICE-001)

Proxy URL schema:
  /play/{provider}/{id}/{quality}
  /play/netease/12345/320k
  /play/youtube/dQw4w9WgXcQ/128k
```

Os serviços QML passam a receber o campo `provider` (=`source`) como parte da resposta do backend e constroem URLs do proxy incluindo-o.

**Pros:**
- Separação limpa: cada provedor é uma unidade testável independente.
- Adicionar um terceiro provedor requer apenas uma nova `struct` que implementa o trait — zero mudanças no router ou nos serviços QML.
- O campo `source` do DB alinha directamente com o segmento `{provider}` do proxy — consistência end-to-end.
- Sem quebra do princípio "Rust trata 100% das chamadas de rede" — o trait vive inteiramente em Rust.
- URL do proxy permanece local (`127.0.0.1:39876`) — o contrato do QML MediaPlayer é preservado.

**Cons:**
- Requer refactoring do código NetEase existente para extrair a implementação do trait.
- O esquema de URL do proxy muda (`/play/{id}/{quality}` → `/play/{provider}/{id}/{quality}`), exigindo actualização dos serviços QML existentes.
- O QML precisa de conhecer o `provider` de cada canção para construir a URL correcta — aumenta ligeiramente a complexidade dos serviços.

---

#### Option B: Instâncias separadas do proxy (uma porta por provedor)

Cada provedor arranca o seu próprio servidor `tiny_http` numa porta dedicada:
- NetEase: `127.0.0.1:39876`
- YouTube Music: `127.0.0.1:39877`
- Provedor N: `127.0.0.1:3987N`

O QML MediaPlayer usa a porta correcta conforme o provedor da canção.

**Pros:**
- Zero mudança no esquema de URL do NetEase existente (retrocompatibilidade total).
- Isolamento de falhas: um provedor a crasha não afecta o outro.

**Cons:**
- Múltiplos threads de servidor e múltiplas portas aumentam o consumo de recursos num dispositivo móvel com memória limitada (PinePhone: 2–3 GB RAM).
- O QML precisa de saber qual porta usar por provedor — acoplamento forte entre UI e infraestrutura de rede.
- Dificulta balanceamento ou fallback entre provedores (ex.: tentar YouTube se NetEase falhar).
- Escala mal: 5 provedores = 5 portas abertas sempre.

---

#### Option C: Gateway QML com múltiplas URLs directas (sem proxy unificado)

Abandonar o proxy local como interface única. O QML MediaPlayer recebe a URL de streaming directa do CDN (NetEase ou YouTube) e conecta-se directamente.

**Pros:**
- Elimina a latência do proxy local.
- Implementação mais simples para o caso YouTube (sem necessidade de re-proxy de streams).

**Cons:**
- **Viola directamente o Princípio de Arquitectura #2 do PRD:** "QML MediaPlayer só pode consumir URLs do proxy local. Nunca URLs directas de CDN."
- Remove a capacidade de injectar headers de autenticação/geo-spoofing de forma centralizada.
- Expõe a lógica de autenticação ao lado QML (JavaScript), que não deve conter segredos.
- Torna impossível implementar rate-limiting, caching ou fallback transparente.
- **Descartada por violar uma restrição arquitectural não-negociável.**

---

### Decision

**Chosen option:** Option A — Trait `MusicProvider` em Rust com routing por prefixo no proxy.

O trait unificado em Rust é o único design que respeita todos os princípios de arquitectura do PRD, escala linearmente com novos provedores, e alinha o campo `source` do DB com a identidade de runtime do provedor sem duplicação de lógica.

---

### Rationale

A Option A é escolhida porque:

1. **Respeita o Princípio #1 (Separação Rust/QML):** toda a lógica de rede, autenticação e transformação de dados vive no trait Rust. O QML continua a ser um consumidor passivo de dados já processados.
2. **Respeita o Princípio #2 (Proxy local como única interface):** a URL do MediaPlayer permanece `http://127.0.0.1:39876/...` — apenas o esquema de path é estendido com o segmento `{provider}`.
3. **Alinha `source` DB ↔ `provider` proxy:** o valor `'youtube'` ou `'netease'` que identifica a entidade no SQLite é o mesmo token que o proxy usa para roteamento — sem transformações ou mapeamentos intermédios.
4. **Custo de extensão O(1):** adicionar Spotify, SoundCloud ou qualquer outro provedor requer implementar o trait e registar a instância no router — zero mudanças em código existente.
5. **Option B** desperdiça recursos num dispositivo móvel e cria acoplamento UI↔porta. **Option C** viola uma restrição arquitectural fundamental e foi descartada imediatamente.

A mudança do esquema de URL do proxy (`/play/{id}/{quality}` → `/play/{provider}/{id}/{quality}`) implica uma actualização dos serviços QML, mas é um custo one-time que evita dívida técnica acumulada em todos os slices futuros.

---

### Consequences

**Positive:**
- Todos os slices futuros de novos provedores têm um contrato claro: implementar `MusicProvider` em Rust e registar no router.
- O campo `source` do DB passa a ter semântica enforced em runtime — o provedor é conhecido antes de qualquer chamada de rede.
- A UI pode mostrar a origem de cada canção (`DesignTokens.js` poderá incluir ícones/cores por provedor) de forma consistente.
- Testes unitários por provedor são possíveis sem modificar o proxy ou os serviços QML.

**Negative / Trade-offs:**
- O refactoring do código NetEase existente para extrair o trait é trabalho adicional em SLICE-001 (estimativa: 1–2 dias para T001-2).
- O esquema de URL do proxy muda — todos os testes de integração existentes que usam URLs `/play/{id}/{quality}` devem ser actualizados.
- O QML precisa de receber e armazenar o campo `provider` em cada objecto `Song` — um campo novo em todos os modelos de dados QML.

**Risks:**
- **Risco de regressão NetEase (ALTO):** a extracção do código NetEase para um trait pode introduzir bugs subtis nos headers de autenticação WeAPI. Mitigação: T001-7 inclui testes de regressão explícitos para todas as funcionalidades NetEase antes de merging.
- **Risco de ToS YouTube Music (ALTO):** a extracção de URLs de stream do YouTube Music sem a YouTube Data API oficial pode violar os Termos de Serviço da Google. Ver secção "Open Questions" do slice SLICE-001. Mitigação: avaliar `piped` ou `invidious` como proxy intermédio; documentar postura legal no README.
- **Risco de incompatibilidade de qualidades (MÉDIO):** NetEase usa `96k/160k/320k`; YouTube Music usa bitrates diferentes. O trait deve normalizar os níveis de qualidade ou expor um mapa de qualidades por provedor. Mitigação: incluir método `supported_qualities() -> Vec<Quality>` no trait.
- **Risco de instabilidade de `yt-dlp`/`rustube` no ambiente clickable (MÉDIO):** dependências para extrair streams YouTube podem não compilar no toolchain ARM/MUSL do clickable. Mitigação: prototipar a compilação em ARM antes de comprometer com a dependência.

---

### Restrições Impostas a Todos os Slices Futuros

As seguintes regras derivam desta decisão e são **obrigatórias** para qualquer slice que introduza ou modifique funcionalidade de streaming:

1. **Todo novo provedor DEVE implementar o trait `MusicProvider` em Rust.** Nenhum provedor pode ser implementado como lógica inline no handler do proxy.
2. **O esquema de URL do proxy é `http://127.0.0.1:39876/play/{provider}/{id}/{quality}`.** Nenhum slice pode introduzir uma rota de proxy que não inclua o segmento `{provider}`.
3. **O valor de `{provider}` DEVE coincidir com o valor de `source` nas tabelas SQLite.** Nenhuma transformação de mapping é permitida — a consistência é por convenção de string (ex.: `'netease'`, `'youtube'`).
4. **O QML NUNCA constrói URLs de CDN externas.** O único URL que o QML MediaPlayer recebe deve ser do proxy local.
5. **Toda entidade musical persistida DEVE incluir `source TEXT NOT NULL`.** Migrações que adicionem tabelas sem este campo serão rejeitadas em code review.
6. **O selector de provedor activo DEVE ser persistido em SQLite (não só em memória).** A preferência do utilizador sobrevive a restarts da app.

---

### Related

- Supersedes: none
- Related slices: SLICE-001 (YouTube Music Provider Support)
- Related artifacts: none
