unit Dext.Auth.JWT;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils,
  System.NetEncoding,
  System.Generics.Collections,
  IdHMACSHA1,
  IdGlobal,
  IdSSLOpenSSL;

type
  /// <summary>
  ///   Represents a claim (key-value pair) in a JWT token.
  /// </summary>
  TClaim = record
    ClaimType: string;
    Value: string;
    constructor Create(const AType, AValue: string);
  end;

  /// <summary>
  ///   JWT token validation result.
  /// </summary>
  TJwtValidationResult = record
    IsValid: Boolean;
    ErrorMessage: string;
    Claims: TArray<TClaim>;
  end;

  /// <summary>
  ///   JWT token generator and validator.
  /// </summary>
  TJwtTokenHandler = class
  private
    FSecretKey: string;
    FIssuer: string;
    FAudience: string;
    FExpirationMinutes: Integer;

    function Base64UrlEncode(const AInput: string): string;
    function Base64UrlDecode(const AInput: string): string;
    function CreateSignature(const AHeader, APayload: string): string;
    function VerifySignature(const AToken: string): Boolean;
  public
    constructor Create(const ASecretKey: string; const AIssuer: string = ''; 
      const AAudience: string = ''; AExpirationMinutes: Integer = 60);

    /// <summary>
    ///   Generates a JWT token with the specified claims.
    /// </summary>
    function GenerateToken(const AClaims: TArray<TClaim>): string;

    /// <summary>
    ///   Validates a JWT token and returns the claims if valid.
    /// </summary>
    function ValidateToken(const AToken: string): TJwtValidationResult;

    /// <summary>
    ///   Extracts claims from a token without full validation (use with caution).
    /// </summary>
    function GetClaims(const AToken: string): TArray<TClaim>;

    property SecretKey: string read FSecretKey write FSecretKey;
    property Issuer: string read FIssuer write FIssuer;
    property Audience: string read FAudience write FAudience;
    property ExpirationMinutes: Integer read FExpirationMinutes write FExpirationMinutes;
  end;

implementation

{ TClaim }

constructor TClaim.Create(const AType, AValue: string);
begin
  ClaimType := AType;
  Value := AValue;
end;

{ TJwtTokenHandler }

constructor TJwtTokenHandler.Create(const ASecretKey, AIssuer, AAudience: string;
  AExpirationMinutes: Integer);
begin
  inherited Create;
  FSecretKey := ASecretKey;
  FIssuer := AIssuer;
  FAudience := AAudience;
  FExpirationMinutes := AExpirationMinutes;
end;

function TJwtTokenHandler.Base64UrlEncode(const AInput: string): string;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(AInput);
  Result := TNetEncoding.Base64.EncodeBytesToString(Bytes);
  
  // Convert to Base64URL format
  Result := Result.Replace('+', '-', [rfReplaceAll]);
  Result := Result.Replace('/', '_', [rfReplaceAll]);
  Result := Result.Replace('=', '', [rfReplaceAll]);
end;

function TJwtTokenHandler.Base64UrlDecode(const AInput: string): string;
var
  Base64: string;
  Bytes: TBytes;
  Padding: Integer;
begin
  Base64 := AInput;
  
  // Convert from Base64URL to standard Base64
  Base64 := Base64.Replace('-', '+', [rfReplaceAll]);
  Base64 := Base64.Replace('_', '/', [rfReplaceAll]);
  
  // Add padding
  Padding := 4 - (Length(Base64) mod 4);
  if Padding < 4 then
    Base64 := Base64 + StringOfChar('=', Padding);
  
  Bytes := TNetEncoding.Base64.DecodeStringToBytes(Base64);
  Result := TEncoding.UTF8.GetString(Bytes);
end;

function TJwtTokenHandler.CreateSignature(const AHeader, APayload: string): string;
var
  HMAC: TIdHMACSHA256;
  Data: string;
  Hash: TIdBytes;
begin
  Data := AHeader + '.' + APayload;
  
  HMAC := TIdHMACSHA256.Create;
  try
    HMAC.Key := ToBytes(FSecretKey, IndyTextEncoding_UTF8);
    Hash := HMAC.HashValue(ToBytes(Data, IndyTextEncoding_UTF8));
    Result := Base64UrlEncode(BytesToString(Hash, IndyTextEncoding_UTF8));
  finally
    HMAC.Free;
  end;
end;

function TJwtTokenHandler.GenerateToken(const AClaims: TArray<TClaim>): string;
var
  Header, Payload: TJSONObject;
  HeaderStr, PayloadStr, Signature: string;
  Claim: TClaim;
  ExpirationTime: TDateTime;
begin
  // Create header
  Header := TJSONObject.Create;
  try
    Header.AddPair('alg', 'HS256');
    Header.AddPair('typ', 'JWT');
    HeaderStr := Base64UrlEncode(Header.ToString);
  finally
    Header.Free;
  end;

  // Create payload
  Payload := TJSONObject.Create;
  try
    // Add standard claims
    if FIssuer <> '' then
      Payload.AddPair('iss', FIssuer);
    
    if FAudience <> '' then
      Payload.AddPair('aud', FAudience);
    
    Payload.AddPair('iat', TJSONNumber.Create(DateTimeToUnix(Now)));
    
    ExpirationTime := IncMinute(Now, FExpirationMinutes);
    Payload.AddPair('exp', TJSONNumber.Create(DateTimeToUnix(ExpirationTime)));
    
    // Add custom claims
    for Claim in AClaims do
      Payload.AddPair(Claim.ClaimType, Claim.Value);
    
    PayloadStr := Base64UrlEncode(Payload.ToString);
  finally
    Payload.Free;
  end;

  // Create signature
  Signature := CreateSignature(HeaderStr, PayloadStr);
  
  Result := HeaderStr + '.' + PayloadStr + '.' + Signature;
end;

function TJwtTokenHandler.VerifySignature(const AToken: string): Boolean;
var
  Parts: TArray<string>;
  ExpectedSignature: string;
begin
  Parts := AToken.Split(['.']);
  if Length(Parts) <> 3 then
    Exit(False);
  
  ExpectedSignature := CreateSignature(Parts[0], Parts[1]);
  Result := Parts[2] = ExpectedSignature;
end;

function TJwtTokenHandler.GetClaims(const AToken: string): TArray<TClaim>;
var
  Parts: TArray<string>;
  PayloadJson: string;
  Payload: TJSONObject;
  Pair: TJSONPair;
  Claims: TList<TClaim>;
  Claim: TClaim;
begin
  SetLength(Result, 0);
  
  Parts := AToken.Split(['.']);
  if Length(Parts) <> 3 then
    Exit;
  
  try
    PayloadJson := Base64UrlDecode(Parts[1]);
    Payload := TJSONObject.ParseJSONValue(PayloadJson) as TJSONObject;
    if Payload = nil then
      Exit;
    
    try
      Claims := TList<TClaim>.Create;
      try
        for Pair in Payload do
        begin
          Claim.ClaimType := Pair.JsonString.Value;
          if Pair.JsonValue is TJSONString then
            Claim.Value := TJSONString(Pair.JsonValue).Value
          else if Pair.JsonValue is TJSONNumber then
            Claim.Value := TJSONNumber(Pair.JsonValue).ToString
          else if Pair.JsonValue is TJSONBool then
            Claim.Value := BoolToStr(TJSONBool(Pair.JsonValue).AsBoolean, True)
          else
            Claim.Value := Pair.JsonValue.ToString;
          
          Claims.Add(Claim);
        end;
        
        Result := Claims.ToArray;
      finally
        Claims.Free;
      end;
    finally
      Payload.Free;
    end;
  except
    SetLength(Result, 0);
  end;
end;

function TJwtTokenHandler.ValidateToken(const AToken: string): TJwtValidationResult;
var
  Claims: TArray<TClaim>;
  Claim: TClaim;
  ExpClaim: string;
  ExpTime: Int64;
begin
  Result.IsValid := False;
  Result.ErrorMessage := '';
  SetLength(Result.Claims, 0);
  
  // Verify signature
  if not VerifySignature(AToken) then
  begin
    Result.ErrorMessage := 'Invalid signature';
    Exit;
  end;
  
  // Get claims
  Claims := GetClaims(AToken);
  if Length(Claims) = 0 then
  begin
    Result.ErrorMessage := 'Invalid token format';
    Exit;
  end;
  
  // Check expiration
  ExpClaim := '';
  for Claim in Claims do
  begin
    if Claim.ClaimType = 'exp' then
    begin
      ExpClaim := Claim.Value;
      Break;
    end;
  end;
  
  if ExpClaim <> '' then
  begin
    ExpTime := StrToInt64Def(ExpClaim, 0);
    if ExpTime > 0 then
    begin
      if DateTimeToUnix(Now) > ExpTime then
      begin
        Result.ErrorMessage := 'Token expired';
        Exit;
      end;
    end;
  end;
  
  // Validate issuer if configured
  if FIssuer <> '' then
  begin
    var IssuerFound := False;
    for Claim in Claims do
    begin
      if (Claim.ClaimType = 'iss') and (Claim.Value = FIssuer) then
      begin
        IssuerFound := True;
        Break;
      end;
    end;
    
    if not IssuerFound then
    begin
      Result.ErrorMessage := 'Invalid issuer';
      Exit;
    end;
  end;
  
  // Validate audience if configured
  if FAudience <> '' then
  begin
    var AudienceFound := False;
    for Claim in Claims do
    begin
      if (Claim.ClaimType = 'aud') and (Claim.Value = FAudience) then
      begin
        AudienceFound := True;
        Break;
      end;
    end;
    
    if not AudienceFound then
    begin
      Result.ErrorMessage := 'Invalid audience';
      Exit;
    end;
  end;
  
  Result.IsValid := True;
  Result.Claims := Claims;
end;

end.
