program WebTUUIDBindingExample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext,
  Dext.Web,
  Dext.Types.UUID;

type
  // DTO with TUUID field
  TProductRequest = record
    Id: TUUID;
    Name: string;
    Price: Double;
  end;

  // Route parameter with TUUID
  TProductIdParam = record
    Id: TUUID;
  end;

procedure ConfigureServices(Services: IServiceCollection);
begin
  // No additional services needed
end;

procedure Configure(App: IWebApplication);
begin
  var WebApp := App.GetBuilder;
  
  WriteLn('═══════════════════════════════════════════════════════════');
  WriteLn('  TUUID Model Binding Example');
  WriteLn('═══════════════════════════════════════════════════════════');
  WriteLn;
  
  // Example 1: TUUID in URL (automatic binding)
  // GET /api/products/{id}
  WebApp.MapGet('/api/products/:id', 
    function(Context: IHttpContext): IResult
    begin
      // TUUID is automatically bound from URL parameter!
      var Param := Context.Request.BindRoute<TProductIdParam>;
      
      WriteLn('GET /api/products/:id');
      WriteLn('  Received UUID: ', Param.Id.ToString);
      WriteLn('  As TGUID: ', GUIDToString(Param.Id.ToGUID));
      
      var Response := Format(
        '{"id": "%s", "name": "Product %s", "price": 99.99}',
        [Param.Id.ToString, Param.Id.ToString.Substring(0, 8)]);
      
      Result := Results.Content(Response, 'application/json');
    end);
  
  // Example 2: TUUID in request body (JSON deserialization)
  // POST /api/products
  // Body: {"id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "name": "New Product", "price": 149.99}
  WebApp.MapPost('/api/products',
    function(Context: IHttpContext): IResult
    begin
      // TUUID is automatically deserialized from JSON!
      var Product := Context.Request.BodyAs<TProductRequest>;
      
      WriteLn('POST /api/products');
      WriteLn('  Received Product:');
      WriteLn('    ID: ', Product.Id.ToString);
      WriteLn('    Name: ', Product.Name);
      WriteLn('    Price: ', Product.Price.ToString);
      
      // Convert to TGUID for database operations
      var DbId: TGUID := Product.Id.ToGUID;
      WriteLn('    DB GUID: ', GUIDToString(DbId));
      
      var Response := Format(
        '{"id": "%s", "name": "%s", "price": %.2f, "created": true}',
        [Product.Id.ToString, Product.Name, Product.Price]);
      
      Result := Results.Created('/api/products/' + Product.Id.ToString, Response);
    end);
  
  // Example 3: TUUID in URL and body (validation)
  // PUT /api/products/{id}
  WebApp.MapPut('/api/products/:id',
    function(Context: IHttpContext): IResult
    begin
      var UrlParam := Context.Request.BindRoute<TProductIdParam>;
      var Product := Context.Request.BodyAs<TProductRequest>;
      
      WriteLn('PUT /api/products/:id');
      WriteLn('  URL ID: ', UrlParam.Id.ToString);
      WriteLn('  Body ID: ', Product.Id.ToString);
      
      // Validate IDs match (TUUID has equality operator!)
      if UrlParam.Id <> Product.Id then
      begin
        WriteLn('  ❌ ID mismatch!');
        Exit(Results.BadRequest('URL ID does not match body ID'));
      end;
      
      WriteLn('  ✅ IDs match');
      WriteLn('  Updating: ', Product.Name);
      
      var Response := Format(
        '{"id": "%s", "name": "%s", "price": %.2f, "updated": true}',
        [Product.Id.ToString, Product.Name, Product.Price]);
      
      Result := Results.Ok(Response);
    end);
  
  // Example 4: Generate UUID v7 and return as TUUID
  // POST /api/products/generate-v7
  WebApp.MapPost('/api/products/generate-v7',
    function(Context: IHttpContext): IResult
    begin
      var NewId := TUUID.NewV7;
      
      WriteLn('POST /api/products/generate-v7');
      WriteLn('  Generated UUID v7: ', NewId.ToString);
      
      var Product: TProductRequest;
      Product.Id := NewId;
      Product.Name := 'Auto-generated Product';
      Product.Price := 0.0;
      
      // Serialize TUUID back to JSON (automatic!)
      var Response := Format(
        '{"id": "%s", "name": "%s", "price": %.2f}',
        [Product.Id.ToString, Product.Name, Product.Price]);
      
      Result := Results.Json(Response);
    end);
  
  // Example 5: Test all UUID formats
  // GET /api/uuid/formats/:id
  WebApp.MapGet('/api/uuid/formats/:id',
    function(Context: IHttpContext): IResult
    begin
      var Param := Context.Request.BindRoute<TProductIdParam>;
      
      WriteLn('GET /api/uuid/formats/:id');
      WriteLn('  Input: ', Context.Request.RouteValues['id']);
      WriteLn('  Parsed as TUUID: ', Param.Id.ToString);
      
      var Response := Format(
        '{"input": "%s", ' +
        '"canonical": "%s", ' +
        '"with_braces": "%s", ' +
        '"as_tguid": "%s"}',
        [Context.Request.RouteValues['id'],
         Param.Id.ToString,
         Param.Id.ToStringWithBraces,
         GUIDToString(Param.Id.ToGUID)]);
      
      Result := Results.Content(Response, 'application/json');
    end);
  
  WriteLn('Available endpoints:');
  WriteLn('──────────────────────────────────────────────────────────');
  WriteLn('  GET    /api/products/:id              - Get by TUUID (URL binding)');
  WriteLn('  POST   /api/products                  - Create with TUUID (body binding)');
  WriteLn('  PUT    /api/products/:id              - Update with TUUID (URL + body)');
  WriteLn('  POST   /api/products/generate-v7      - Generate UUID v7');
  WriteLn('  GET    /api/uuid/formats/:id          - Test UUID format parsing');
  WriteLn;
  WriteLn('Example requests:');
  WriteLn('──────────────────────────────────────────────────────────');
  WriteLn('  # Get product (accepts any UUID format)');
  WriteLn('  curl http://localhost:8080/api/products/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
  WriteLn('  curl http://localhost:8080/api/products/{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}');
  WriteLn;
  WriteLn('  # Create product');
  WriteLn('  curl -X POST http://localhost:8080/api/products \');
  WriteLn('    -H "Content-Type: application/json" \');
  WriteLn('    -d ''{"id":"a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11","name":"Test","price":99.99}''');
  WriteLn;
  WriteLn('  # Generate UUID v7');
  WriteLn('  curl -X POST http://localhost:8080/api/products/generate-v7');
  WriteLn;
  WriteLn('  # Test formats');
  WriteLn('  curl http://localhost:8080/api/uuid/formats/a0eebc999c0b4ef8bb6d6bb9bd380a11');
  WriteLn('═══════════════════════════════════════════════════════════');
  WriteLn('Server listening on http://localhost:8080');
  WriteLn('Press Ctrl+C to stop');
  WriteLn;
end;

var
  App: IWebApplication;
begin
  try
    App := TWebApplication.Create;
    App.ConfigureServices(ConfigureServices);
    App.Configure(Configure);
    App.Run('http://localhost:8080');
  except
    on E: Exception do
      WriteLn('Error: ', E.Message);
  end;
end.
