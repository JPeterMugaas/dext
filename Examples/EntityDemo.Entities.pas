unit EntityDemo.Entities;

interface

uses
  Dext.Entity.Attributes,
  Dext.Specifications.Base,
  Dext.Specifications.Criteria,
  Dext.Specifications.Interfaces;

type
  [Table('addresses')]
  TAddress = class
  private
    FId: Integer;
    FStreet: string;
    FCity: string;
  public
    [PK, AutoInc]
    property Id: Integer read FId write FId;
    property Street: string read FStreet write FStreet;
    property City: string read FCity write FCity;
  end;

  [Table('users')]
  TUser = class
  private
    FId: Integer;
    FName: string;
    FAge: Integer;
    FEmail: string;
    FAddress: TAddress;
  public
    [PK, AutoInc]
    property Id: Integer read FId write FId;

    [Column('full_name')]
    property Name: string read FName write FName;

    property Age: Integer read FAge write FAge;
    property Email: string read FEmail write FEmail;

    [ForeignKey('AddressId', caCascade)]  // CASCADE on delete
    property Address: TAddress read FAddress write FAddress;
  end;

  [Table('order_items')]
  TOrderItem = class
  private
    FOrderId: Integer;
    FProductId: Integer;
    FQuantity: Integer;
    FPrice: Double;
  public
    [PK, Column('order_id')]
    property OrderId: Integer read FOrderId write FOrderId;

    [PK,Column('product_id')]
    property ProductId: Integer read FProductId write FProductId;

    property Quantity: Integer read FQuantity write FQuantity;
    property Price: Double read FPrice write FPrice;
  end;

  [Table('products')]
  TProduct = class
  private
    FId: Integer;
    FName: string;
    FPrice: Double;
    FVersion: Integer;
  public
    [PK, AutoInc]
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
    property Price: Double read FPrice write FPrice;
    
    [Version]
    property Version: Integer read FVersion write FVersion;
  end;

  // 🧬 Metadata Prototype (TypeOf)
  UserEntity = class
  public
    class function Age: TProp;
    class function Name: TProp;
  end;

  // Specification using Metadata
  TAdultUsersSpec = class(TSpecification<TUser>)
  public
    constructor Create; override;
  end;

implementation

{ UserEntity }

class function UserEntity.Age: TProp;
begin
  Result := Prop('Age');
end;

class function UserEntity.Name: TProp;
begin
  Result := Prop('full_name');
end;

{ TAdultUsersSpec }

constructor TAdultUsersSpec.Create;
begin
  inherited Create;
  Where(UserEntity.Age >= 18);
end;

end.
