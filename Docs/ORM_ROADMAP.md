# Roadmap Dext ORM

Este documento mapeia as funcionalidades do Dext ORM em comparação com o Entity Framework, definindo o status atual e o roadmap de prioridades para o desenvolvimento.

## 📊 Comparativo de Features

| Feature | Entity Framework | Dext ORM (Atual) | Status | Prioridade |
| :--- | :--- | :--- | :--- | :--- |
| **Basic CRUD** | `Add`, `Update`, `Remove`, `Find` | `Add`, `Find`, `List` implementados. `Update` e `Remove` vazios. | ⚠️ Incompleto | 🚨 **Crítica** |
| **Querying** | LINQ (`Where`, `Select`) | Specifications (`Criteria`) | ✅ Implementado | - |
| **Mapping** | Attributes & Fluent API | Attributes apenas | ⚠️ Parcial | 📉 Baixa |
| **Relationships** | Navigation Props (1:N, N:N) | Não suportado | ❌ Ausente | 🔥 **Média** |
| **Change Tracking**| Automático (`SaveChanges`) | Explícito (`Update` method) | ❌ Ausente | 📉 Baixa (Decisão de Design) |
| **Migrations** | `Add-Migration` | Manual SQL | ❌ Ausente | 📉 Baixa |
| **Identity Map** | Cache local de entidades (L1) | Não existe (cada query cria novos objetos) | ❌ Ausente | 🔥 **Média** |
| **Concurrency** | Optimistic Concurrency | Não suportado | ❌ Ausente | 📉 Baixa |

---

## 🗺️ Roadmap de Implementação

Com base na análise, definimos as seguintes fases para estabilizar o ORM.

### 📍 Fase 1: Core CRUD & Estabilidade (Imediato)
*O objetivo é tornar o ORM funcional para operações básicas de persistência.*

1.  **Implementar `TDbSet<T>.Update`**:
    *   ✅ Implementado (Gera SQL dinâmico).
2.  **Implementar `TDbSet<T>.Remove`**:
    *   ✅ Implementado (Gera SQL DELETE).
3.  **Refinar Conversão de Tipos (`Hydrate`)**:
    *   ✅ **Base Implementada**: `Dext.Core.ValueConverters` criado com suporte a Primitivos, Enums, GUIDs e Datas.

### 📍 Fase 2: Relacionamentos Básicos (Curto Prazo)
*Permitir carregar dados relacionados sem complexidade excessiva.*

1.  **Suporte a Foreign Keys**:
    *   ✅ Atributo `[ForeignKey('ColumnId')]` implementado.
2.  **Eager Loading Simples**:
    *   ✅ Capacidade de carregar objetos filhos (ex: `User.Address`) implementada via `Hydrate`.

### 📍 Fase 3: Produtividade & Tooling (Médio Prazo)
1.  **Identity Map**:
    *   ✅ Implementado cache local no `TDbSet<T>` (`FIdentityMap`).
    *   `Find(1)` retorna a mesma instância se já carregada.
    *   Entidades são gerenciadas pelo contexto (User não deve liberar).
2.  **Gerador de Schema (Básico)**:
    *   ✅ Método `EnsureCreated()` implementado.
    *   Gera SQL `CREATE TABLE` baseado nos metadados da entidade e dialeto.
    *   ✅ **Estável**: Bugs de interface e AV resolvidos.

### 📍 Fase 4: Cenários Avançados & Legado (Longo Prazo)
1.  **Chaves Primárias Compostas**:
    *   ✅ **IMPLEMENTADO**: Suporte completo a múltiplos campos com `[PK]`.
    *   ✅ `Find` aceita array de valores (`Find([100, 50])`).
    *   ✅ Identity Map adaptado para chaves compostas (usa string "val1|val2").
    *   ✅ `GenerateCreateTableScript` gera `PRIMARY KEY (col1, col2)` para composite keys.
    *   ✅ `Add`, `Update`, `Remove` funcionam corretamente com composite keys.
2.  **Transações Aninhadas / Savepoints**: Melhor controle transacional.
3.  **Lazy Loading**: Proxies virtuais para carregar listas grandes sob demanda.

---

## 🎯 Próximas Features Sugeridas

### Opção 1: **Lazy Loading** (Alta Complexidade, Alto Impacto)
- Carregar relacionamentos sob demanda (ex: `user.Orders` carrega automaticamente quando acessado)
- Requer proxies ou interceptação de propriedades
- **Impacto**: Melhora significativa na performance e usabilidade

### Opção 2: **Fluent API para Mapping** (Média Complexidade, Médio Impacto)
- Alternativa aos atributos: `modelBuilder.Entity<User>().HasKey(x => x.Id)`
- Permite configuração mais flexível e centralizada
- **Impacto**: Melhora a organização e permite cenários complexos

### Opção 3: **Migrations Básicas** (Alta Complexidade, Alto Impacto)
- Geração automática de scripts de migração (diff entre modelos)
- Versionamento de schema
- **Impacto**: Essencial para produção e evolução do schema

### Opção 4: **Optimistic Concurrency** (Média Complexidade, Médio Impacto)
- Suporte a `[Timestamp]` ou `[RowVersion]`
- Detecta conflitos de concorrência em `Update`
- **Impacto**: Importante para aplicações multi-usuário

### Opção 5: **Cascade Delete & Update** (Baixa-Média Complexidade, Médio Impacto)
- Configurar comportamento de FK: `ON DELETE CASCADE`, `ON UPDATE CASCADE`
- Implementar no `GenerateCreateTableScript`
- **Impacto**: Melhora integridade referencial

### Opção 6: **Bulk Operations** (Média Complexidade, Alto Impacto)
- `AddRange`, `UpdateRange`, `RemoveRange` otimizados
- Executar múltiplas operações em uma única transação/comando
- **Impacto**: Performance significativa para grandes volumes

---

## 🗄️ Roadmap de Suporte a Bancos de Dados

### Status Atual
- ✅ **SQLite**: Suporte completo e testado
- ⚠️ **PostgreSQL**: Dialeto implementado, mas não validado completamente

### Expansão Planejada (Baseada em Pesquisa de Mercado Delphi)

#### Prioridade 1 - Crítica (Mercado BR + Prototipagem)
1. **Firebird 3.0/4.0**
   - **Segmento**: ERPs Modernos, Mercado BR
   - **Driver**: FireDAC (TFDPhysFBDriverLink)
   - **Desafios**: Dialeto SQL, Transações, Generators
   - **Status**: ❌ Não implementado

2. **SQLite** ✅
   - **Segmento**: Mobile, Testes, Prototipagem
   - **Driver**: FireDAC (TFDPhysSQLiteDriverLink)
   - **Desafios**: Concorrência (Locking), Tipos
   - **Status**: ✅ **Implementado e Validado**

#### Prioridade 2 - Alta (Legado + Cloud)
3. **Firebird 2.5**
   - **Segmento**: Legado, Migração
   - **Driver**: FireDAC (TFDPhysFBDriverLink)
   - **Desafios**: Paginação (FirstSkip), Boolean
   - **Status**: ❌ Não implementado (pode reutilizar dialeto FB 3.0/4.0)

4. **PostgreSQL**
   - **Segmento**: Microserviços, Cloud, Docker
   - **Driver**: FireDAC (TFDPhysPGDriverLink)
   - **Desafios**: JSONB, Case Sensitivity, Batch
   - **Status**: ⚠️ **Dialeto criado, precisa validação completa**

#### Prioridade 3 - Média (Corporativo)
5. **SQL Server**
   - **Segmento**: Corporativo, Integração .NET
   - **Driver**: FireDAC (TFDPhysMSSQLDriverLink)
   - **Desafios**: Schemas, Tipos DateTime
   - **Status**: ❌ Não implementado

6. **MySQL/MariaDB**
   - **Segmento**: Web Hosting, Linux Barato
   - **Driver**: FireDAC (TFDPhysMySQLDriverLink)
   - **Desafios**: Transações Aninhadas, Engines
   - **Status**: ❌ Não implementado

#### Prioridade 4 - Baixa (Legado Oracle)
7. **Oracle**
   - **Segmento**: Grandes Corporações
   - **Driver**: FireDAC (TFDPhysOracleDriverLink)
   - **Desafios**: Sequences, Tipos
   - **Status**: ❌ Não implementado

### Plano de Implementação de Dialetos

**Fase 1: Validação Completa (Imediato)**
- Criar suite de testes para SQLite (todas as features)
- Validar PostgreSQL com testes automatizados
- Documentar diferenças e limitações

**Fase 2: Firebird (Prioridade Crítica - Mercado BR)**
- Implementar `TFirebirdDialect` (FB 3.0/4.0)
- Suporte a Generators (`GEN_ID`)
- Tratamento de `FIRST/SKIP` para paginação
- Testes com FireDAC

**Fase 3: SQL Server (Corporativo)**
- Implementar `TSQLServerDialect`
- Suporte a `IDENTITY` e `SCOPE_IDENTITY()`
- Schemas (`dbo.TableName`)
- Tipos específicos (`DATETIME2`, `NVARCHAR`)

**Fase 4: MySQL/MariaDB (Web)**
- Implementar `TMySQLDialect`
- Auto-increment
- Engine selection (InnoDB vs MyISAM)

**Fase 5: Oracle (Opcional)**
- Implementar `TOracleDialect`
- Sequences
- Tipos específicos

### Estratégia de Testes por Banco

```pascal
// Estrutura sugerida para testes
TDatabaseTestSuite = class
  procedure TestBasicCRUD;
  procedure TestCompositeKeys;
  procedure TestRelationships;
  procedure TestTransactions;
  procedure TestConcurrency;
  procedure TestBulkOperations;
end;

// Executar para cada dialeto:
// - SQLite
// - PostgreSQL
// - Firebird
// - SQL Server
// - MySQL
// - Oracle
```

---

## 📋 Ordem de Implementação Recomendada

### Curto Prazo (1-2 semanas)
1. ✅ **Cascade Delete & Update** - Fundação
2. ✅ **Bulk Operations** - Performance
3. ✅ **Optimistic Concurrency** - Segurança

### Médio Prazo (3-4 semanas)
4. **Validação Completa PostgreSQL** - Testar todas as features
5. **Firebird 3.0/4.0 Dialect** - Mercado BR (Crítico!)
6. **Suite de Testes Automatizados** - Garantir qualidade

### Longo Prazo (2-3 meses)
7. **SQL Server Dialect** - Corporativo
8. **MySQL/MariaDB Dialect** - Web
9. **Lazy Loading** - UX avançada
10. **Migrations** - Produção


