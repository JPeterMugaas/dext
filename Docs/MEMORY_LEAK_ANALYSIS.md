# Análise de Memory Leaks - Dext ORM

## Status Atual (2025-12-02)

### Leaks Resolvidos ✅
1. **TModelBuilder** - Corrigido adicionando `FModelBuilder.Free` no destrutor de `TDbContext`
2. **TObjectDictionary<PTypeInfo, TEntityMap>** - Corrigido com `[doOwnsValues]` no `TModelBuilder`
3. **ChangeTracker dangling pointers** - Corrigido com:
   - Custom `TEqualityComparer<TObject>` baseado em ponteiros
   - `Remove()` method para remover entidades antes de deletar
   - `Clear()` no destrutor de `TDbContext`

### Leaks Pendentes 🔍

#### 1. RTTI System Leaks (Baixa Prioridade)
**Tipo:** `System.Rtti.TFinalizer`, `TRttiInstancePropertyEx`, `TRttiInstanceMethodEx`
**Causa:** Leaks internos do sistema RTTI do Delphi ao fazer reflexão de atributos
**Impacto:** Pequeno (28-36 bytes cada)
**Ação:** Não há muito o que fazer - são limitações do RTTI do Delphi

**Exemplos:**
```
- 28 bytes: System.Rtti.TFinalizer (allocation #49580)
- 32 bytes: System.Rtti.LazyLoadAttributes.MakeClosure$ActRec
- 36 bytes: System.Rtti.TRttiInstanceMethodEx
```

#### 2. Lazy Loading / TVirtualInterface Leaks (Média Prioridade)
**Tipo:** `System.Rtti.TVirtualInterface.TImplInfo`, closures relacionados
**Causa:** Interfaces virtuais criadas para lazy loading não sendo liberadas corretamente
**Impacto:** Médio (16-24 bytes por entidade)
**Localização:** `Dext.Entity.LazyLoading.pas` linha 193

**Stack Trace:**
```
TLazyInjector.InjectField -> TVirtualInterface.Create
```

**Ação Recomendada:**
- Revisar o ciclo de vida das interfaces virtuais em `TLazyInjector`
- Considerar usar weak references ou um pool de interfaces

#### 3. FluentQuery Closure Leaks (Alta Prioridade)
**Tipo:** `Dext.Entity.Query.@TFluentQuery`1.Skip$ActRec`, `Take$ActRec`
**Causa:** Closures (funções anônimas) capturando variáveis não sendo liberadas
**Impacto:** Médio (28 bytes por closure)
**Localização:** `Dext.Entity.Query.pas` linhas 486-510

**Código Problemático:**
```pascal
function TFluentQuery<T>.Skip(const ACount: Integer): TFluentQuery<T>;
var
  LSource: TEnumerable<T>;
begin
  LSource := Self;  // Captura Self
  Result := TFluentQuery<T>.Create(
    function: TQueryIterator<T>
    begin
      Result := TSkipIterator<T>.Create(LSource, ACount);  // Closure captura LSource
    end,
    TObject(Self));
end;
```

**Ação Recomendada:**
- Evitar captura de variáveis locais em closures
- Passar parâmetros diretamente para os iteradores
- Considerar usar métodos nomeados ao invés de closures anônimas

#### 4. Attribute Leaks (Baixa Prioridade)
**Tipo:** `Dext.Entity.Attributes.ColumnAttribute`
**Causa:** Atributos criados via RTTI não sendo liberados
**Impacto:** Pequeno (12 bytes)
**Localização:** Criação via RTTI durante `MapEntity`

**Ação:** Verificar se os atributos estão sendo corretamente liberados após uso

#### 5. Unknown Leaks (Investigação Necessária)
**Tipo:** Unknown (6152 bytes, 200 bytes)
**Causa:** Não identificada - possivelmente arrays dinâmicos do RTTI
**Impacto:** Médio a Alto
**Ação:** Requer investigação mais profunda com stack traces

## Melhorias Implementadas

### Const Correctness
Aplicado `const` em parâmetros de tipos gerenciados (interfaces, strings, records) em:
- `TDbContext.Create`
- `TDbSet<T>.Create`
- `TCollectionEntry.Create`, `TReferenceEntry.Create`, `TEntityEntry.Create`
- `TDbSet<T>.Hydrate`

### Memory Management
- `FIdentityMap` com `[doOwnsValues]` para gerenciar lifecycle de entidades
- `FChangeTracker.Clear()` antes de destruir DbSets
- `FChangeTracker.Remove()` antes de deletar entidades
- `FModelBuilder.Free` no destrutor de `TDbContext`

## Próximos Passos

1. **Prioridade Alta:**
   - Resolver leaks de FluentQuery closures
   - Investigar Unknown leaks de 6152 bytes

2. **Prioridade Média:**
   - Otimizar lazy loading para reduzir leaks de TVirtualInterface
   - Adicionar testes específicos para detectar leaks

3. **Prioridade Baixa:**
   - Documentar limitações conhecidas do RTTI
   - Considerar alternativas ao uso intensivo de RTTI

## Ferramentas Utilizadas

- **FastMM5** com FullDebugMode
- Stack traces detalhados com símbolos de debug
- Testes isolados para identificar fontes de leaks

## Notas

- Muitos dos leaks são inerentes ao uso de RTTI no Delphi
- O impacto total dos leaks é relativamente pequeno (< 10KB por execução completa dos testes)
- A estratégia de testar incrementalmente (um teste por vez) está funcionando bem
