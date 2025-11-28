unit EntityDemo.Tests.CRUD;

interface

uses
  System.SysUtils,
  EntityDemo.Tests.Base,
  EntityDemo.Entities;

type
  TCRUDTest = class(TBaseTest)
  public
    procedure Run; override;
  end;

implementation

{ TCRUDTest }

procedure TCRUDTest.Run;
var
  User: TUser;
  Address: TAddress;
begin
  Log('🚀 Running CRUD Tests...');
  Log('========================');

  // 1. Insert
  Log('📝 Testing Insert...');
  
  Address := TAddress.Create;
  Address.Street := '123 Main St';
  Address.City := 'New York';
  // Note: We are relying on Cascade Insert now!
  
  User := TUser.Create;
  User.Name := 'Alice';
  User.Age := 25;
  User.Email := 'alice@dext.com';
  User.Address := Address; // Link address
  
  FContext.Entities<TUser>.Add(User);
  
  AssertTrue(User.Id > 0, 
    Format('User inserted with ID: %d', [User.Id]), 
    'User ID is 0 or empty after insert!');
    
  AssertTrue(Address.Id > 0, 
    Format('Address inserted with ID: %d', [Address.Id]), 
    'Address ID is 0 or empty after insert (Cascade failed)!');

  // 2. Read (Find)
  Log('🔍 Testing Find...');
  var FoundUser := FContext.Entities<TUser>.Find(User.Id);
  
  AssertTrue(FoundUser <> nil, 'User found.', 'User not found.');
  if FoundUser <> nil then
  begin
    AssertTrue(FoundUser.Name = 'Alice', 'User Name is correct.', 'User Name is incorrect.');
    AssertTrue(FoundUser.Address <> nil, 'Address loaded.', 'Address not loaded.');
    if FoundUser.Address <> nil then
      AssertTrue(FoundUser.Address.City = 'New York', 'Address City is correct.', 'Address City is incorrect.');
  end;

  // 3. Update
  Log('🔄 Testing Update...');
  if FoundUser <> nil then
  begin
    FoundUser.Age := 26;
    FContext.Entities<TUser>.Update(FoundUser);
    
    // Verify
    var UpdatedUser := FContext.Entities<TUser>.Find(User.Id);
    AssertTrue(UpdatedUser.Age = 26, 'User Age updated to 26.', 'User Age update failed.');
  end;

  // 4. Delete
  Log('🗑️ Testing Delete...');
  if FoundUser <> nil then
  begin
    FContext.Entities<TUser>.Remove(FoundUser);
    
    var DeletedUser := FContext.Entities<TUser>.Find(User.Id);
    AssertTrue(DeletedUser = nil, 'User removed successfully.', 'User still exists after remove.');
  end;
  
  Log('');
end;

end.
