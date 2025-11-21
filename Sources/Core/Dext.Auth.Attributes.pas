unit Dext.Auth.Attributes;

interface

uses
  System.SysUtils,
  System.Rtti;

type
  /// <summary>
  ///   Marks a handler as requiring authentication.
  /// </summary>
  AuthorizeAttribute = class(TCustomAttribute)
  private
    FRoles: string;
  public
    constructor Create; overload;
    constructor Create(const ARoles: string); overload;
    
    property Roles: string read FRoles;
  end;

  /// <summary>
  ///   Marks a handler as allowing anonymous access (bypasses authentication).
  /// </summary>
  AllowAnonymousAttribute = class(TCustomAttribute)
  end;

implementation

{ AuthorizeAttribute }

constructor AuthorizeAttribute.Create;
begin
  inherited Create;
  FRoles := '';
end;

constructor AuthorizeAttribute.Create(const ARoles: string);
begin
  inherited Create;
  FRoles := ARoles;
end;

end.
