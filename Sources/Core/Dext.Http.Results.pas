unit Dext.Http.Results;

interface

uses
  System.SysUtils,
  Dext.Http.Interfaces,
  Dext.Json;

type
  TResult = class(TInterfacedObject, IResult)
  protected
    procedure Execute(AContext: IHttpContext); virtual; abstract;
  end;

  TJsonResult = class(TResult)
  private
    FJson: string;
    FStatusCode: Integer;
  public
    constructor Create(const AJson: string; AStatusCode: Integer = 200);
    procedure Execute(AContext: IHttpContext); override;
  end;

  TStatusCodeResult = class(TResult)
  private
    FStatusCode: Integer;
  public
    constructor Create(AStatusCode: Integer);
    procedure Execute(AContext: IHttpContext); override;
  end;

  TContentResult = class(TResult)
  private
    FContent: string;
    FContentType: string;
    FStatusCode: Integer;
  public
    constructor Create(const AContent: string; const AContentType: string = 'text/plain'; AStatusCode: Integer = 200);
    procedure Execute(AContext: IHttpContext); override;
  end;

  Results = class
  public
    class function Ok: IResult; overload;
    class function Ok(const AValue: string): IResult; overload;
    class function Ok<T>(const AValue: T): IResult; overload;
    
    class function Created(const AUri: string; const AValue: string): IResult; overload;
    class function Created<T>(const AUri: string; const AValue: T): IResult; overload;

    class function BadRequest: IResult; overload;
    class function BadRequest(const AError: string): IResult; overload;
    
    class function NotFound: IResult; overload;
    class function NotFound(const AMessage: string): IResult; overload;

    class function NoContent: IResult;
    
    class function Json(const AJson: string; AStatusCode: Integer = 200): IResult;
    class function Text(const AContent: string; AStatusCode: Integer = 200): IResult;
    class function StatusCode(ACode: Integer): IResult; overload;
    class function StatusCode(ACode: Integer; const AContent: string): IResult; overload;
  end;

implementation

{ TJsonResult }

constructor TJsonResult.Create(const AJson: string; AStatusCode: Integer);
begin
  inherited Create;
  FJson := AJson;
  FStatusCode := AStatusCode;
end;

procedure TJsonResult.Execute(AContext: IHttpContext);
begin
  AContext.Response.StatusCode := FStatusCode;
  AContext.Response.Json(FJson);
end;

{ TStatusCodeResult }

constructor TStatusCodeResult.Create(AStatusCode: Integer);
begin
  inherited Create;
  FStatusCode := AStatusCode;
end;

procedure TStatusCodeResult.Execute(AContext: IHttpContext);
begin
  AContext.Response.StatusCode := FStatusCode;
end;

{ TContentResult }

constructor TContentResult.Create(const AContent, AContentType: string; AStatusCode: Integer);
begin
  inherited Create;
  FContent := AContent;
  FContentType := AContentType;
  FStatusCode := AStatusCode;
end;

procedure TContentResult.Execute(AContext: IHttpContext);
begin
  AContext.Response.StatusCode := FStatusCode;
  AContext.Response.SetContentType(FContentType);
  AContext.Response.Write(FContent);
end;

{ Results }

class function Results.Ok: IResult;
begin
  Result := TStatusCodeResult.Create(200);
end;

class function Results.Ok(const AValue: string): IResult;
begin
  Result := TJsonResult.Create(AValue, 200);
end;

class function Results.Ok<T>(const AValue: T): IResult;
begin
  Result := TJsonResult.Create(TDextJson.Serialize<T>(AValue), 200);
end;

class function Results.Created(const AUri, AValue: string): IResult;
begin
  // TODO: Set Location header
  Result := TJsonResult.Create(AValue, 201);
end;

class function Results.Created<T>(const AUri: string; const AValue: T): IResult;
begin
  Result := TJsonResult.Create(TDextJson.Serialize<T>(AValue), 201);
end;

class function Results.BadRequest: IResult;
begin
  Result := TStatusCodeResult.Create(400);
end;

class function Results.BadRequest(const AError: string): IResult;
begin
  Result := TJsonResult.Create(Format('{"error": "%s"}', [AError]), 400);
end;

class function Results.NotFound: IResult;
begin
  Result := TStatusCodeResult.Create(404);
end;

class function Results.NotFound(const AMessage: string): IResult;
begin
  Result := TJsonResult.Create(Format('{"error": "%s"}', [AMessage]), 404);
end;

class function Results.NoContent: IResult;
begin
  Result := TStatusCodeResult.Create(204);
end;

class function Results.Json(const AJson: string; AStatusCode: Integer): IResult;
begin
  Result := TJsonResult.Create(AJson, AStatusCode);
end;

class function Results.Text(const AContent: string; AStatusCode: Integer): IResult;
begin
  Result := TContentResult.Create(AContent, 'text/plain', AStatusCode);
end;

class function Results.StatusCode(ACode: Integer): IResult;
begin
  Result := TStatusCodeResult.Create(ACode);
end;

class function Results.StatusCode(ACode: Integer; const AContent: string): IResult;
begin
  Result := TJsonResult.Create(AContent, ACode);
end;

end.
