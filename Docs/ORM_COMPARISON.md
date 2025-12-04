# ⚔️ ORM Feature Comparison

Este documento apresenta um comparativo técnico detalhado entre o **Dext Entity**, **TMS Aurelius** (o padrão de mercado atual em Delphi) e **Entity Framework Core** (a referência de mercado global em .NET).

> **Objetivo:** Posicionar o Dext Entity como uma alternativa moderna, focada em performance e DX (Developer Experience), trazendo conceitos do EF Core para o ecossistema Delphi.

---

## 🏆 Tabela Comparativa Geral

| Funcionalidade | ⚡ Dext Entity | 🏛️ TMS Aurelius | 🔷 EF Core (.NET) |
| :--- | :---: | :---: | :---: |
| **Filosofia** | Code-First / Fluent / **Db-First** | Code-First / Attributes | Code-First / Model-First |
| **Query API** | **Fluent & Typed** (Specification) | Criteria API (Strings/Objects) | **LINQ** (Language Integrated) |
| **Change Tracking** | ✅ Snapshot / Unit of Work | ✅ Object Manager | ✅ Snapshot / Proxies |
| **Performance** | 🚀 **High** (RTTI Cache + Direct SQL) | ⚠️ Medium (Heavy RTTI) | 🚀 High (Compiled Queries) |
| **Memory Management** | ✅ **Smart Lists / Interfaces** (Roadmap) | ❌ Manual (`Free`) | ✅ GC Nativo (.NET) |
| **Lazy Loading** | ✅ Proxies / `ILazy<T>` | ✅ Proxies / Blob | ✅ Proxies |
| **Eager Loading** | ✅ `.Include('Prop')` | ✅ Prefetch | ✅ `.Include(x => x.Prop)` |
| **Batch Operations** | ✅ `AddRange`, `RemoveRange` | ❌ Iterativo | ✅ `ExecuteUpdate/Delete` |
| **Migrations** | 🚧 Planejado (v1.0) | ✅ TAureliusDataset | ✅ Powerhouse (CLI/Code) |
| **Multi-Database** | ✅ (On Demand) | ✅ (Vasto suporte) | ✅ (Vasto suporte) |
| **Async Support** | 🚧 Futures / Tasks | ✅ Async/Await (Parcial) | ✅ Full Async/Await |
| **Nullables** | ✅ **Nativo** (`Nullable<T>`) | ✅ `Nullable<T>` | ✅ `T?` |
| **Composite Keys** | ✅ Suporte Completo | ✅ Suporte Completo | ✅ Suporte Completo |
| **License** | 🆓 **Open Source** | 💰 Comercial (Pago) | 🆓 Open Source (MIT) |

---

## 🔍 Análise Detalhada

### 1. Developer Experience (DX) & Querying

**Dext Entity** brilha na DX ao trazer uma API fluente que se aproxima muito do LINQ, algo que falta no Delphi nativo.

*   **Dext Entity**:
    ```delphi
    // Type-safe, Fluent, Intuitivo
    Context.Entities<TUser>
           .Where(User.Age >= 18)
           .OrderBy(User.Name.Asc)
           .Take(10)
           .ToList();
    ```
*   **TMS Aurelius**:
    ```delphi
    // Verboso, depende de strings ou geradores de criteria complexos
    Manager.Find<TUser>
           .Add(TExpression.Ge('Age', 18))
           .AddOrder(TOrder.Asc('Name'))
           .Take(10)
           .List;
    ```
*   **EF Core**:
    ```csharp
    // O "Gold Standard"
    context.Users
           .Where(u => u.Age >= 18)
           .OrderBy(u => u.Name)
           .Take(10)
           .ToList();
    ```

### 2. Performance & Overhead

*   **Dext Entity**: Projetado com "Performance First". Utiliza cache de RTTI agressivo e evita reflection em loops críticos (hot paths). O novo roadmap inclui compilação prévia de metadados para zerar o custo de startup.
*   **TMS Aurelius**: Extremamente maduro e estável, mas conhecido por ter um overhead de reflection considerável, especialmente na hidratação de grandes listas de objetos.
*   **EF Core**: Beneficia-se do compilador Roslyn e JIT do .NET. O Dext busca emular isso gerando SQL otimizado (ex: `LIMIT 1` para `FirstOrDefault`) e evitando roundtrips desnecessários.

### 3. Gerenciamento de Memória

Aqui reside o maior diferencial proposto para o futuro do Dext.

*   **Delphi (Padrão/Aurelius)**: O desenvolvedor é responsável por destruir tudo. `try..finally` hell.
    ```delphi
    List := Manager.Find<TUser>.List;
    try
      // use list
    finally
      List.Free; // Manager pode ou não ser dono dos objetos
    end;
    ```
*   **Dext Entity (Roadmap)**: Introdução de `IList<T>` gerenciada e "Garbage Collector" de framework.
    ```delphi
    // No leaks, destruction automática ao sair do escopo
    var Users: IList<TUser> := Context.Entities<TUser>.List;
    ```

### 4. Ecossistema & Modernidade

*   **Dext**: Nasceu na era da nuvem. Já possui `Nullable<T>`, suporte a JSON nativo, e arquitetura desacoplada pronta para Injeção de Dependência.
*   **Aurelius**: Framework legado robusto. Carrega bagagem de compatibilidade com versões muito antigas do Delphi, o que limita a adoção de features novas da linguagem.

---

## 💡 Conclusão

O **Dext Entity** não tenta competir em "quantidade de bancos suportados" com o Aurelius (que suporta dezenas), mas sim na **qualidade da experiência de desenvolvimento** e **performance** para os bancos modernos mais usados (PostgreSQL, SQL Server, Firebird).

Ele preenche a lacuna de um "EF Core para Delphi", oferecendo uma sintaxe moderna e limpa que atrai desenvolvedores acostumados com C# ou Java, mantendo a performance nativa do Delphi.
