---
description: How to add new extensions to the Dext fluent API
---

# Extending the Dext Fluent API

Due to Delphi limitations (no helpers for interfaces, no generic methods in interfaces), Dext uses a wrapper record `TDextServices` to provide a fluent API for `IServiceCollection`.

To add new extension methods (e.g., `AddMyFeature`), follow these steps:

1.  **Create a Record Helper**:
    Define a `record helper` for `TDextServices` in your unit (or in `DextFramework.pas` if it's core).

    ```pascal
    type
      TDextServicesHelper = record helper for TDextServices
      public
        function AddMyFeature: TDextServices;
      end;
    ```

2.  **Implement the Method**:
    Use `Self.Unwrap` to access the underlying `IServiceCollection`.

    ```pascal
    function TDextServicesHelper.AddMyFeature: TDextServices;
    begin
      // Register your services
      Self.Unwrap.AddSingleton<IMyService, TMyService>;
      
      // Return Self to continue the chain
      Result := Self;
    end;
    ```

3.  **Usage**:
    Users can now use your method fluently:

    ```pascal
    App.Services
      .AddSingleton<IFoo, TFoo>
      .AddMyFeature
      .BuildServiceProvider;
    ```

## Core DI Methods
Core generic methods (`AddSingleton<T>`, etc.) are defined directly on `TDextServices` in `Dext.DI.Interfaces.pas`.
