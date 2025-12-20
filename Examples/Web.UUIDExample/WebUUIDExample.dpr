program WebUUIDExample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext,
  Dext.Web,
  Dext.Types.UUID;

type
  TProductDto = record
    Id: TGUID;
    Name: string;
    Price: Double;
  end;

procedure ConfigureServices(Services: IServiceCollection);
begin
  // No additional services needed for this simple example
end;

procedure Configure(App: IWebApplication);
begin
  var WebApp := App.GetBuilder;
  
  // Example 1: GET with UUID in URL path
  // GET /api/products/{id}
  WebApp.MapGet('/api/products/:id', 
    function(Context: IHttpContext): IResult
    begin
      var IdStr := Context.Request.RouteValues['id'];
      WriteLn('Received ID from URL: ', IdStr);
      
      try
        // Parse UUID from URL (accepts with or without braces/hyphens)
        var U := TUUID.FromString(IdStr);
        var ProductId: TGUID := U.ToGUID;
        
        WriteLn('Parsed as GUID: ', GUIDToString(ProductId));
        WriteLn('Canonical UUID: ', U.ToString);
        
        // Simulate database lookup
        var Product: TProductDto;
        Product.Id := ProductId;
        Product.Name := 'Sample Product';
        Product.Price := 99.99;
        
        Result := Results.Json(Product);
      except
        on E: Exception do
          Result := Results.BadRequest('Invalid UUID format: ' + E.Message);
      end;
    end);
  
  // Example 2: POST with UUID in request body
  // POST /api/products
  // Body: {"id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "name": "New Product", "price": 49.99}
  WebApp.MapPost('/api/products',
    function(Context: IHttpContext): IResult
    begin
      try
        var Dto := Context.Request.BodyAs<TProductDto>;
        
        WriteLn('Received product from body:');
        WriteLn('  ID: ', GUIDToString(Dto.Id));
        WriteLn('  Name: ', Dto.Name);
        WriteLn('  Price: ', Dto.Price.ToString);
        
        // Convert to TUUID for database storage
        var U := TUUID.FromGUID(Dto.Id);
        WriteLn('  UUID (for DB): ', U.ToString);
        
        // Simulate database insert
        WriteLn('Product created successfully!');
        
        Result := Results.Created('/api/products/' + U.ToString, Dto);
      except
        on E: Exception do
          Result := Results.BadRequest('Invalid request: ' + E.Message);
      end;
    end);
  
  // Example 3: PUT with UUID in both URL and body
  // PUT /api/products/{id}
  WebApp.MapPut('/api/products/:id',
    function(Context: IHttpContext): IResult
    begin
      var IdStr := Context.Request.RouteValues['id'];
      
      try
        var UrlId := TUUID.FromString(IdStr);
        var Dto := Context.Request.BodyAs<TProductDto>;
        var BodyId := TUUID.FromGUID(Dto.Id);
        
        // Validate that URL ID matches body ID
        if UrlId <> BodyId then
          Exit(Results.BadRequest('URL ID does not match body ID'));
        
        WriteLn('Updating product: ', UrlId.ToString);
        WriteLn('  New Name: ', Dto.Name);
        WriteLn('  New Price: ', Dto.Price.ToString);
        
        Result := Results.Ok(Dto);
      except
        on E: Exception do
          Result := Results.BadRequest('Invalid request: ' + E.Message);
      end;
    end);
  
  // Example 4: Generate new UUID v7
  // POST /api/products/generate
  WebApp.MapPost('/api/products/generate',
    function(Context: IHttpContext): IResult
    begin
      var U := TUUID.NewV7;
      
      WriteLn('Generated UUID v7: ', U.ToString);
      
      var Product: TProductDto;
      Product.Id := U.ToGUID;
      Product.Name := 'Auto-generated Product';
      Product.Price := 0.0;
      
      Result := Results.Json(Product);
    end);
  
  // Example 5: Test endpoint showing all formats
  // GET /api/uuid/test
  WebApp.MapGet('/api/uuid/test',
    function(Context: IHttpContext): IResult
    begin
      var U := TUUID.NewV7;
      var G: TGUID := U.ToGUID;
      
      var Response := Format(
        '{"uuid_v7": "%s", ' +
        '"with_braces": "%s", ' +
        '"tguid": "%s", ' +
        '"timestamp_ms": %d}',
        [U.ToString, U.ToStringWithBraces, GUIDToString(G), DateTimeToUnix(Now) * 1000]);
      
      Result := Results.Content(Response, 'application/json');
    end);
  
  WriteLn('Web UUID Example Server');
  WriteLn('=======================');
  WriteLn;
  WriteLn('Available endpoints:');
  WriteLn('  GET    /api/products/:id          - Get product by UUID');
  WriteLn('  POST   /api/products              - Create product (UUID in body)');
  WriteLn('  PUT    /api/products/:id          - Update product (UUID in URL and body)');
  WriteLn('  POST   /api/products/generate     - Generate new UUID v7');
  WriteLn('  GET    /api/uuid/test             - Test UUID formats');
  WriteLn;
  WriteLn('Example requests:');
  WriteLn('  curl http://localhost:8080/api/products/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
  WriteLn('  curl -X POST http://localhost:8080/api/products -H "Content-Type: application/json" -d "{\"id\":\"a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11\",\"name\":\"Test\",\"price\":99.99}"');
  WriteLn('  curl -X POST http://localhost:8080/api/products/generate');
  WriteLn('  curl http://localhost:8080/api/uuid/test');
  WriteLn;
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
