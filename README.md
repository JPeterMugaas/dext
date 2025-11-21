# Dext Framework - Modern Web API Framework for Delphi

**Dext** é um framework web moderno para Delphi inspirado em ASP.NET Core Minimal APIs, trazendo recursos avançados como Smart Binding, Dependency Injection, Result Helpers e Validação Automática.

## 🚀 Recursos Principais

### 1. **Minimal API com Smart Binding**
Crie endpoints de forma fluente e expressiva:

```pascal
// GET com parâmetro de rota
App.MapGetR<Integer, IResult>('/api/users/{id}',
  function(UserId: Integer): IResult
  begin
    Result := Results.Json(Format('{"userId":%d}', [UserId]));
  end);

// POST com body binding automático
App.MapPostR<TCreateUserRequest, IResult>('/api/users',
  function(Request: TCreateUserRequest): IResult
  begin
    Result := Results.Created('/api/users/1', '{"status":"created"}');
  end);
```

### 2. **Result Helpers**
Retorne respostas HTTP de forma elegante:

```pascal
Results.Ok('{"message":"Success"}');           // 200 OK
Results.Created('/api/users/1', '{}');         // 201 Created
Results.BadRequest('{"error":"Invalid"}');     // 400 Bad Request
Results.NotFound();                            // 404 Not Found
Results.NoContent();                           // 204 No Content
Results.Json('{}', 200);                       // Custom status
```

### 3. **Dependency Injection**
Injete serviços automaticamente nos handlers:

```pascal
// Registrar serviço
Services.AddSingleton<IUserService, TUserService>;

// Usar no handler
App.MapPost<TUser, IUserService, IHttpContext>('/api/users',
  procedure(User: TUser; UserService: IUserService; Ctx: IHttpContext)
  begin
    UserService.CreateUser(User);
    Ctx.Response.Json('{"status":"created"}');
  end);
```

### 4. **Validação Automática**
Valide DTOs usando atributos:

```pascal
type
  TCreateUserRequest = record
    [Required]
    [StringLength(3, 50)]
    Name: string;
    
    [Required]
    [EmailAddress]
    Email: string;
    
    [Range(18, 120)]
    Age: Integer;
  end;

// No handler
var
  Validator := TValidator<TCreateUserRequest>.Create;
  ValidationResult := Validator.Validate(Request);
  
if not ValidationResult.IsValid then
  Result := Results.BadRequest(GetErrorsJson(ValidationResult));
```

**Atributos disponíveis:**
- `[Required]` - Campo obrigatório
- `[StringLength(min, max)]` - Tamanho da string
- `[EmailAddress]` - Validação de email
- `[Range(min, max)]` - Faixa numérica

### 5. **Middleware Funcional**
Crie middlewares inline sem classes:

```pascal
App.Use(
  procedure(Context: IHttpContext; Next: TRequestDelegate)
  begin
    WriteLn('Request: ' + Context.Request.Path);
    Next(Context);
    WriteLn('Response sent');
  end);
```

### 6. **Autenticação JWT** 🔐
Sistema completo de autenticação com JSON Web Tokens:

```pascal
// Configurar middleware de autenticação
var Options := TJwtAuthenticationOptions.Default('my-secret-key');
App.UseMiddleware(TJwtAuthenticationMiddleware, TValue.From(Options));

// Endpoint de login (gera token)
App.MapPostR<TLoginRequest, IResult>('/api/auth/login',
  function(Request: TLoginRequest): IResult
  var
    Claims: TArray<TClaim>;
    Token: string;
  begin
    // Validar credenciais
    if ValidateUser(Request) then
    begin
      // ✅ Criar claims com fluent builder
      Claims := TClaimsBuilder.Create
        .WithNameIdentifier('123')
        .WithName(Request.Username)
        .WithRole('Admin')
        .Build;
      
      Token := JwtHandler.GenerateToken(Claims);
      Result := Results.Ok(Format('{"token":"%s"}', [Token]));
    end
    else
      Result := Results.BadRequest('{"error":"Invalid credentials"}');
  end);

// Endpoint protegido (requer autenticação)
App.MapGetR<IHttpContext, IResult>('/api/protected',
  function(Context: IHttpContext): IResult
  begin
    if (Context.User = nil) or not Context.User.Identity.IsAuthenticated then
      Result := Results.StatusCode(401, '{"error":"Unauthorized"}')
    else
      Result := Results.Ok(Format('{"user":"%s"}', [Context.User.Identity.Name]));
  end);
```

**Recursos:**
- Geração e validação de tokens JWT (HMAC-SHA256)
- Claims-based identity
- Autorização baseada em roles (`IsInRole`)
- Middleware automático de autenticação
- **Claims Builder** com fluent interface para criar claims elegantemente

```pascal
// Sintaxe fluente para criar claims
var Claims := TClaimsBuilder.Create
  .WithNameIdentifier('123')
  .WithName('john.doe')
  .WithEmail('john@example.com')
  .WithRole('Admin')
  .WithRole('User')  // Múltiplas roles
  .AddClaim('custom', 'value')  // Claims personalizados
  .Build;
```

📚 **[Documentação Completa de JWT](docs/JWT-Authentication.md)**

### 7. **CORS (Cross-Origin Resource Sharing)** 🌐
Configure CORS de forma simples e segura:

```pascal
uses
  Dext.Http.Cors;

// ✅ Desenvolvimento - Permitir qualquer origem
TApplicationBuilderCorsExtensions.UseCors(Builder,
  procedure(Cors: TCorsBuilder)
  begin
    Cors
      .AllowAnyOrigin
      .AllowAnyMethod
      .AllowAnyHeader;
  end);

// ✅ Produção - Origens específicas
TApplicationBuilderCorsExtensions.UseCors(Builder,
  procedure(Cors: TCorsBuilder)
  begin
    Cors
      .WithOrigins(['https://myapp.com', 'https://www.myapp.com'])
      .WithMethods(['GET', 'POST', 'PUT', 'DELETE'])
      .WithHeaders(['Content-Type', 'Authorization'])
      .AllowCredentials
      .WithMaxAge(3600); // Cache preflight por 1 hora
  end);
```

**Recursos:**
- Builder fluente para configuração elegante
- Suporte a preflight requests (OPTIONS)
- Múltiplas origens ou wildcard (*)
- Configuração de métodos, headers e credentials
- Cache de preflight configurável

📚 **[Documentação Completa de CORS](docs/CORS.md)**

### 8. **Rate Limiting** 🚦
Proteja sua API contra abuso e ataques DDoS:

```pascal
uses
  Dext.RateLimiting;

// ✅ Padrão - 100 requisições por minuto
TApplicationBuilderRateLimitExtensions.UseRateLimiting(Builder);

// ✅ Personalizado
TApplicationBuilderRateLimitExtensions.UseRateLimiting(Builder,
  procedure(RateLimit: TRateLimitBuilder)
  begin
    RateLimit
      .WithPermitLimit(50)      // 50 requests
      .WithWindow(60)            // per 60 seconds
      .WithRejectionMessage('{"error":"Too many requests"}')
      .WithRejectionStatusCode(429);
  end);
```

**Recursos:**
- Builder fluente para configuração
- Thread-safe com `TCriticalSection`
- Headers informativos (X-RateLimit-*)
- Limpeza automática de entradas expiradas
- Baseado em IP do cliente

**Headers retornados:**
```
X-RateLimit-Limit: 50
X-RateLimit-Remaining: 45
Retry-After: 60 (quando limitado)
```

📚 **[Documentação Completa de Rate Limiting](docs/Rate-Limiting.md)**

### 9. **Smart Binding Automático**
O framework detecta automaticamente a origem dos parâmetros:

| Tipo | Origem | Exemplo |
|------|--------|---------|
| `Integer`, `String`, etc. | Route ou Query | `/users/{id}` |
| `Record` | Body (POST/PUT) ou Query (GET) | JSON → Record |
| `Interface` | DI Container | `IUserService` |
| `IHttpContext` | Framework | Acesso direto ao contexto |

## 📦 Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/dext.git
cd dext
```

2. Adicione os paths ao seu projeto:
```
Sources\Core
Sources\Core\Drivers
```

3. Adicione as units necessárias:
```pascal
uses
  Dext.Core.WebApplication,
  Dext.Core.ApplicationBuilder.Extensions,
  Dext.Http.Results,
  Dext.Validation,
  Dext.DI.Extensions;
```

## 🎯 Exemplo Completo

```pascal
program MyAPI;

uses
  Dext.Core.WebApplication,
  Dext.Core.ApplicationBuilder.Extensions,
  Dext.Http.Results,
  Dext.Validation,
  Dext.DI.Extensions;

type
  TCreateUserRequest = record
    [Required]
    [StringLength(3, 50)]
    Name: string;
    
    [Required]
    [EmailAddress]
    Email: string;
    
    [Range(18, 120)]
    Age: Integer;
  end;

  IUserService = interface
    ['{GUID}']
    function CreateUser(const Request: TCreateUserRequest): Integer;
  end;

  TUserService = class(TInterfacedObject, IUserService)
  public
    function CreateUser(const Request: TCreateUserRequest): Integer;
  end;

function TUserService.CreateUser(const Request: TCreateUserRequest): Integer;
begin
  // Lógica de criação
  Result := 1;
end;

var
  App: IWebApplication;
begin
  App := TDextApplication.Create;
  
  // Configurar DI
  App.Services.AddSingleton<IUserService, TUserService>;
  
  var Builder := App.GetApplicationBuilder;
  
  // Middleware de logging
  Builder.Use(
    procedure(Ctx: IHttpContext; Next: TRequestDelegate)
    begin
      WriteLn('Request: ' + Ctx.Request.Path);
      Next(Ctx);
    end);
  
  // Rotas
  Builder.MapGetR<IResult>('/',
    function: IResult
    begin
      Result := Results.Ok('{"message":"Welcome to Dext API"}');
    end);
  
  Builder.MapPostR<TCreateUserRequest, IUserService, IResult>('/api/users',
    function(Request: TCreateUserRequest; UserService: IUserService): IResult
    var
      Validator: IValidator<TCreateUserRequest>;
      ValidationResult: TValidationResult;
      UserId: Integer;
    begin
      // Validar
      Validator := TValidator<TCreateUserRequest>.Create;
      ValidationResult := Validator.Validate(Request);
      
      if not ValidationResult.IsValid then
      begin
        Result := Results.BadRequest('{"error":"Validation failed"}');
        ValidationResult.Free;
        Exit;
      end;
      
      ValidationResult.Free;
      
      // Criar usuário
      UserId := UserService.CreateUser(Request);
      
      Result := Results.Created(
        Format('/api/users/%d', [UserId]),
        Format('{"id":%d,"name":"%s"}', [UserId, Request.Name])
      );
    end);
  
  App.Run(8080);
  ReadLn;
end.
```

## 🧪 Testando

Execute o exemplo `Dext.MinimalAPITest.dpr`:

```bash
cd Sources\Tests
dcc32 -B Dext.MinimalAPITest.dpr
Dext.MinimalAPITest.exe
```

Teste com curl:

```bash
# GET simples
curl http://localhost:8080/api/users/123

# POST válido
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","age":30}'

# POST inválido (falha na validação)
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Jo","email":"invalid","age":15}'
```

## 📚 Estrutura do Projeto

```
Dext/
├── Sources/
│   ├── Core/
│   │   ├── Dext.Http.Interfaces.pas       # Interfaces principais
│   │   ├── Dext.Http.Results.pas          # Result Helpers
│   │   ├── Dext.Core.HandlerInvoker.pas   # Invocação de handlers
│   │   ├── Dext.Core.ModelBinding.pas     # Smart Binding
│   │   ├── Dext.Validation.pas            # Framework de validação
│   │   ├── Dext.DI.Core.pas               # Dependency Injection
│   │   └── Drivers/                       # Drivers JSON
│   ├── Examples/
│   │   └── TaskFlowAPI/                   # Exemplo completo
│   └── Tests/
│       └── Dext.MinimalAPITest.dpr        # Suite de testes
```

## 🔧 Arquitetura

### Pipeline de Requisição

```
Request → Middlewares → Routing → Model Binding → Handler → Result → Response
```

1. **Middlewares**: Processamento antes/depois (logging, auth, etc.)
2. **Routing**: Encontra o handler correto baseado no path
3. **Model Binding**: Converte dados da requisição em parâmetros tipados
4. **Handler**: Sua lógica de negócio
5. **Result**: Converte o retorno em resposta HTTP

### Convenções de Nomenclatura

- **`Map*`**: Métodos que retornam `void` ou manipulam `IHttpContext` diretamente
- **`Map*R`**: Métodos que retornam `IResult` (Result Helpers)

Exemplo:
```pascal
// Tradicional
MapPost<TUser, IHttpContext>(...);

// Com Result Helpers
MapPostR<TUser, IResult>(...);
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 🙏 Agradecimentos

- Inspirado por ASP.NET Core Minimal APIs
- Comunidade Delphi

---

**Desenvolvido com ❤️ usando Delphi**
