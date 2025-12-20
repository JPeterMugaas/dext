# Web UUID Example

Este exemplo demonstra como trabalhar com UUIDs em APIs web usando o Dext Framework.

## Funcionalidades Demonstradas

### 1. UUID em Parâmetros de URL
```http
GET /api/products/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11
```
O framework automaticamente extrai o UUID da URL e converte para `TGUID`.

### 2. UUID no Body da Requisição (JSON)
```http
POST /api/products
Content-Type: application/json

{
  "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
  "name": "Produto Teste",
  "price": 99.99
}
```
O `BodyAs<TProductDto>` deserializa automaticamente o UUID do JSON.

### 3. UUID em URL e Body (PUT)
```http
PUT /api/products/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11
Content-Type: application/json

{
  "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
  "name": "Produto Atualizado",
  "price": 149.99
}
```
Valida que o ID da URL corresponde ao ID do body.

### 4. Geração de UUID v7 (Time-Ordered)
```http
POST /api/products/generate
```
Gera um novo UUID v7 que é ordenável por tempo, ideal para chaves primárias de banco de dados.

## Formatos de UUID Aceitos

O `TUUID.FromString()` aceita múltiplos formatos:

- **Canônico** (recomendado): `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11`
- **Com chaves** (Delphi): `{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}`
- **Sem hífens**: `a0eebc999c0b4ef8bb6d6bb9bd380a11`
- **Maiúsculas**: `A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11`

## Conversão Automática

O tipo `TUUID` possui operadores implícitos que facilitam o uso:

```pascal
// String → TUUID
var U: TUUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

// TUUID → String
var S: string := U; // Retorna formato canônico (lowercase, sem chaves)

// TGUID → TUUID (cuida do endianness automaticamente)
var G: TGUID;
CreateGUID(G);
U := G;

// TUUID → TGUID
G := U;
```

## Uso com Banco de Dados

### PostgreSQL
```pascal
// Salvar (TUUID gera string limpa para PostgreSQL)
var U := TUUID.NewV7;
Query.SQL.Text := 'INSERT INTO products (id, name) VALUES (:id, :name)';
Query.ParamByName('id').AsString := U.ToString; // Sem chaves!

// Carregar
Query.SQL.Text := 'SELECT id, name FROM products WHERE id = :id';
Query.ParamByName('id').AsString := U.ToString;
Query.Open;
var LoadedId := TUUID.FromString(Query.FieldByName('id').AsString);
```

### Com ORM Dext
```pascal
[Table('products')]
TProduct = class
private
  FId: TGUID; // Use TGUID normalmente
  FName: string;
public
  [PK]
  property Id: TGUID read FId write FId;
  property Name: string read FName write FName;
end;

// O TGuidConverter cuida da conversão automaticamente
var Product := TProduct.Create;
Product.Id := TUUID.NewV7.ToGUID; // ou apenas: TUUID.NewV7
Db.Products.Add(Product);
Db.SaveChanges;

// Find funciona corretamente agora!
var Loaded := Db.Products.Find(Product.Id);
```

## Por Que TUUID?

### Problema
Delphi's `TGUID` usa Little-Endian para os primeiros 8 bytes, mas PostgreSQL e APIs web esperam Big-Endian (RFC 9562). Isso causava:
- GUIDs salvos incorretamente no banco
- `Find()` não encontrava registros
- Incompatibilidade com APIs externas

### Solução
`TUUID` armazena bytes em Big-Endian internamente e converte automaticamente de/para `TGUID`, garantindo compatibilidade total.

## UUID v4 vs UUID v7

### UUID v4 (Random)
```pascal
var U := TUUID.NewV4; // Totalmente aleatório
```
- ✅ Máxima entropia
- ❌ Ruim para índices de banco (causa fragmentação)

### UUID v7 (Time-Ordered) - **Recomendado**
```pascal
var U := TUUID.NewV7; // Ordenado por tempo
```
- ✅ Ordenável lexicograficamente
- ✅ Excelente para índices B-Tree
- ✅ Performance similar a BIGINT AUTO_INCREMENT
- ✅ Mantém unicidade global

## Como Executar

1. Compile o projeto
2. Execute `WebUUIDExample.exe`
3. Teste os endpoints com curl ou Postman

### Exemplos de Teste

```bash
# GET com UUID na URL
curl http://localhost:8080/api/products/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11

# POST com UUID no body
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{"id":"a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11","name":"Produto Novo","price":99.99}'

# Gerar novo UUID v7
curl -X POST http://localhost:8080/api/products/generate

# Testar formatos
curl http://localhost:8080/api/uuid/test
```

## Referências

- [RFC 9562 - UUID](https://www.rfc-editor.org/rfc/rfc9562.html)
- [UUID v7 Specification](https://www.ietf.org/archive/id/draft-peabody-dispatch-new-uuid-format-04.html)
- [PostgreSQL UUID Type](https://www.postgresql.org/docs/current/datatype-uuid.html)
